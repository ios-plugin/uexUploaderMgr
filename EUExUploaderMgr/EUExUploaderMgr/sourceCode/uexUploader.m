/**
 *
 *	@file   	: uexUploader.m  in EUExUploaderMgr
 *
 *	@author 	: CeriNo 
 * 
 *	@date   	: Created on 16/5/3.
 *
 *	@copyright 	: 2016 The AppCan Open Source Project.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "uexUploader.h"
#import "JSON.h"
#import "EUExUploaderMgr.h"
#import "uexUploadFile.h"


#import "uexUploadInfo.h"
#import "uexGlobalUploaderManager.h"

@implementation uexUploader


- (instancetype)initWithIdentifier:(NSString *)identidier serverURL:(NSString *)serverURL euexObj:(EUExUploaderMgr *)euexObj{
    self = [super init];
    if (self) {
        _identifier = identidier;
        _euexObj = euexObj;
        _observer = euexObj.webViewEngine;
        _files = [NSMutableDictionary dictionary];
        _serverURL = serverURL;
        _type = uexUploaderTypeDefault;
        [self setHeaders:nil];
        [self setupSessionManager];
    }
    return self;
}



- (void)appendDataWithFilePath:(NSString *)filePath field:(NSString *)field editingImageWithScaledWidth:(CGFloat)scaledWidth compressLevel:(NSInteger)compressLevel{
    if (!filePath || filePath.length == 0 || !field || field.length == 0) {
        return;
    }
    if ([self.files.allKeys containsObject:field]) {
        return;
    }
    
    uexUploadFile *file = [[uexUploadFile alloc]initWithFilePath:filePath];
    [file editImageWithScaledWidth:scaledWidth compressLevel:compressLevel];
    [self.files setObject:file forKey:field];
}


- (void)setHeaders:(NSDictionary *)headers{
    __block NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionaryWithDictionary:[uexUploadHelper AppCanHTTPHeadersWithEUExObj:self.euexObj]];
    [headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [mutableHeaders setValue:obj forKey:key];
    }];
    _headers = [mutableHeaders copy];

}

- (void)setupSessionManager{
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    [manager setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    [manager setSessionDidBecomeInvalidBlock:^(NSURLSession * _Nonnull session, NSError * _Nonnull error) {
        if (self.type != uexUploaderTypeDefault) {
            [uexGlobalUploaderMgr uexUploaderDidCompleteUploadTask:self];
        }else{
            self.status = uexUploaderStatusFailure;
            [self.euexObj uexUploaderDidCompleteUploadTask:self];
        }
    }];
    manager.securityPolicy.allowInvalidCertificates = YES;
    manager.securityPolicy.validatesDomainName = NO;
    self.sessionManager = manager;
}

- (void)startUpload{

    ACLogDebug(@"=> uexUploader '%@' start uploading!",self.identifier);
    AFHTTPRequestSerializer *reqSerializer = [AFHTTPRequestSerializer serializer];
    [self.headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [reqSerializer setValue:obj forHTTPHeaderField:key];
    }];
    [self.sessionManager setRequestSerializer:reqSerializer];
    self.task = [self.sessionManager POST:self.serverURL
                               parameters:nil
                constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                                    [self.files enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, uexUploadFile * _Nonnull obj, BOOL * _Nonnull stop) {
                                        NSData *data = obj.fileData;
                                        if (data) {
                                            [formData appendPartWithFileData:data  name:key fileName:obj.fileName mimeType:obj.MIMEType];
                                        }
                                    }];
                                    [self.files removeAllObjects];
                                }
                                 progress:^(NSProgress * _Nonnull uploadProgress) {
                                     self.totalSize = uploadProgress.totalUnitCount;
                                     self.status = uexUploaderStatusUploading;
                                     NSInteger percent = (NSInteger)(uploadProgress.fractionCompleted * 100);
                                     if (percent == 0 || percent == 100 || percent != self.percent) {
                                         ACLogDebug(@"=> uexUploader '%@' uploading...%@%%",self.identifier,@(percent));
                                         self.percent = percent;
                                         [self onStatusCallback];
                                         if (self.type != uexUploaderTypeDefault) {
                                             [uexGlobalUploaderMgr uexUploaderDidUploadData:self];
                                         }else{
                                             [self.euexObj uexUploaderDidUploadData:self];
                                         }
                                     }
                                     
                                 }
                                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                      NSString *response = [responseObject isKindOfClass:[NSData class]] ? [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding] :[NSString stringWithFormat:@"%@",responseObject];
                                      ACLogDebug(@"=> uexUploader '%@' SUCCESS! response:%@",self.identifier,response);
                                      self.responseString = response;
                                      self.percent = 100;
                                      self.status = uexUploaderStatusSuccess;
                                      [self onStatusCallback];
                                      [self.sessionManager invalidateSessionCancelingTasks:YES];
                                      
                                  }
                                  failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                      ACLogDebug(@"=> uexUploader '%@' FAIL! error:%@",self.identifier,error.localizedDescription);
                                      self.status = uexUploaderStatusFailure;
                                      [self onStatusCallback];
                                      [self.sessionManager invalidateSessionCancelingTasks:YES];
                                  }];
    
}




- (void)onStatusCallback{
    if (!self.observer) {
        return;
    }
    [self.observer callbackWithFunctionKeyPath:@"uexUploaderMgr.onStatus" arguments:ACArgsPack(self.identifier,@(self.totalSize),@(self.percent),self.responseString,@(self.status))];
    [self.cb executeWithArguments:ACArgsPack(@(self.totalSize),@(self.percent),self.responseString,@(self.status))];
    
}

- (void)cancelUpload{
    [self.sessionManager invalidateSessionCancelingTasks:YES];
    
}


- (void)dealloc{
    //NSLog(@"uexUploader dealloc");
}
@end
