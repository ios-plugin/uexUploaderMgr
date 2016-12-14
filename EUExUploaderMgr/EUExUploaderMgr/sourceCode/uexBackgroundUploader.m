/**
 *
 *	@file   	: uexBackgroundUploader.m  in EUExUploaderMgr
 *
 *	@author 	: CeriNo 
 * 
 *	@date   	: Created on 16/5/13.
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

#import "uexBackgroundUploader.h"
#import "uexUploadInfo.h"
#import <AFNetworking/AFNetworking.h>
#import "uexGlobalUploaderManager.h"
#import "uexUploadFile.h"
#import <AppCanKit/ACEXTScope.h>
static NSString * kUexBackgroundUploadSessionPrefix;
static NSString * kUexBackgroundUploadTempFileFolderPath;


@interface uexUploadBackgroundSessionManager : AFURLSessionManager

- (instancetype)initWithIdentifier:(NSString *)identifier;

@end


@interface uexBackgroundUploader()


@end

@implementation uexBackgroundUploader

+ (void)initialize{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundleId = [[NSBundle mainBundle].infoDictionary objectForKey:(NSString *)kCFBundleIdentifierKey];
        kUexBackgroundUploadSessionPrefix = [bundleId stringByAppendingString:@".uexUploaderMgr_backgroundUploader_"];
        kUexBackgroundUploadTempFileFolderPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"uexUploaderMgrBackgroundCache"];
        if (![[NSFileManager defaultManager]fileExistsAtPath:kUexBackgroundUploadTempFileFolderPath]) {
            NSError *error = nil;
            [[NSFileManager defaultManager]createDirectoryAtPath:kUexBackgroundUploadTempFileFolderPath withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
                ACLogDebug(@"uexUploaderMgr create background temp file folder FAILED!error:%@",error.localizedDescription);
            }
        }
    });
    
}

+ (NSString *)sessionPrefix{
    return kUexBackgroundUploadSessionPrefix;
}

- (instancetype)initWithIdentifier:(NSString *)identidier serverURL:(NSString *)serverURL euexObj:(EUExUploaderMgr *)euexObj
{
    self = [super initWithIdentifier:identidier serverURL:serverURL euexObj:euexObj];
    if (self) {
        self.type = uexUploaderTypeBackground;
        self.tempFilePath = [kUexBackgroundUploadTempFileFolderPath stringByAppendingPathComponent:self.identifier];
        
    }
    return self;
}

+ (instancetype)resumeWithInfo:(uexUploadInfo *)info{
    if (info.type != uexUploaderTypeBackground) {
        return nil;
    }
    uexBackgroundUploader *uploader = [[self alloc] initWithIdentifier:info.identifier serverURL:info.serverURL euexObj:nil];
    uploader.responseString = info.responseString;
    uploader.percent = info.percent;
    uploader.status = info.status;
    uploader.totalSize = info.totalSize;
    uploader.headers = info.headers;
    return uploader;
}


- (void)setupSessionManager{
    self.sessionManager = [[uexUploadBackgroundSessionManager alloc]initWithIdentifier:self.identifier];
    self.sessionManager.securityPolicy.allowInvalidCertificates = YES;
    self.sessionManager.securityPolicy.validatesDomainName = NO;

}


- (void)startUpload{
    
    AFHTTPRequestSerializer *reqSerializer = [AFHTTPRequestSerializer serializer];
    [self.headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [reqSerializer setValue:obj forHTTPHeaderField:key];
    }];
    [self.sessionManager setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    NSError *error = nil;
    NSMutableURLRequest *request = [reqSerializer multipartFormRequestWithMethod:@"POST" URLString:self.serverURL parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [self.files enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, uexUploadFile * _Nonnull obj, BOOL * _Nonnull stop) {
            [formData appendPartWithFileData:obj.fileData  name:key fileName:obj.fileName mimeType:obj.MIMEType];
        }];
        [self.files removeAllObjects];
    } error:&error];
    
    if (error) {
        ACLogDebug(@"=> uexBackgroundUploader '%@' form data FAILED!error:%@",self.identifier,error.localizedDescription);
    }
    
    NSURL *tmpURL = [NSURL fileURLWithPath:self.tempFilePath];
    if ([[NSFileManager defaultManager]fileExistsAtPath:tmpURL.path]) {
        [[NSFileManager defaultManager]removeItemAtURL:tmpURL error:nil];
    }
    
    __block NSMutableURLRequest *req = [reqSerializer requestWithMultipartFormRequest:request writingStreamContentsToFile:tmpURL completionHandler:^(NSError * _Nullable error) {
        if (error) {
            ACLogDebug(@"=> uexBackgroundUploader '%@' make temp file FAILED!error:%@",self.identifier,error.localizedDescription);
            self.status = uexUploaderStatusFailure;
            [self onStatusCallback];
            [[uexUploadInfo infoForUploader:self]save];
            [self.sessionManager invalidateSessionCancelingTasks:YES];
            return ;
        }
        self.task = [self.sessionManager
                     uploadTaskWithRequest:req
                     fromFile:tmpURL
                     progress:^(NSProgress * _Nonnull uploadProgress) {
                         self.totalSize = uploadProgress.totalUnitCount;
                         self.status = uexUploaderStatusUploading;
                         NSInteger percent = (NSInteger)(uploadProgress.fractionCompleted * 100);
                         if (percent == 0 || percent == 100 || percent != self.percent) {
                             ACLogDebug(@"=> uexBackgroundUploader '%@' uploading...%@%%",self.identifier,@(percent));
                             self.percent = percent;
                             [self onStatusCallback];
                             [uexGlobalUploaderMgr uexUploaderDidUploadData:self];
                         }
                     }
                     completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                         if ([responseObject isKindOfClass:[NSData class]]) {
                             self.responseString = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
                         }
                        if (error) {
                             self.status = uexUploaderStatusFailure;
                             ACLogDebug(@"=> uexBackgroundUploader '%@' FAILED! error:%@",self.identifier,error.localizedDescription);
                         }else{
                             self.percent = 100;
                             self.status = uexUploaderStatusSuccess;
                             ACLogDebug(@"=> uexBackgroundUploader '%@' SUCCESS! response:%@",self.identifier,response);
                         }
                         [self onStatusCallback];
                         
                     }];
        ACLogDebug(@"=> uexBackgroundUploader '%@' start uploading!",self.identifier);
        [self.task resume];
    }];
    
    
    
    
}

@end








@interface uexUploadBackgroundSessionManager()
@property (nonatomic,strong)NSString *identifier;
@property (nonatomic,strong,readonly)NSString *sessionIdentifier;
@property (nonatomic,strong)NSMutableData *responseData;
@end



@implementation uexUploadBackgroundSessionManager

static dispatch_queue_t _uexUploadMgrBackgroundOperationQueue;


+ (void)initialize{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _uexUploadMgrBackgroundOperationQueue = dispatch_queue_create("com.appcan.uexUploadMgrBackgroundOperationQueue", DISPATCH_QUEUE_CONCURRENT);
    });
}


- (instancetype)initWithIdentifier:(NSString *)identifier
{
    _identifier = identifier;
    
    NSURLSessionConfiguration *config = ACSystemVersion() > 8.0 ? [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[self sessionIdenfifier]]: [NSURLSessionConfiguration backgroundSessionConfiguration:[self sessionIdenfifier]];
    self = [super initWithSessionConfiguration:config];
    if (self) {
        _responseData = [NSMutableData data];
        [self setDidFinishEventsForBackgroundURLSessionBlock:^(NSURLSession * _Nonnull session) {
            //不设置这个空block,URLSessionDidFinishEventsForBackgroundURLSession:有时会不执行...
            //怀疑是一个bug
        }];
        @weakify(self);
        [self setDataTaskDidReceiveDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSData * _Nonnull data) {
            @strongify(self);
            [self.responseData appendData:data];
        }];
        
    }
    return self;
}
- (NSString *)sessionIdenfifier{
    return [kUexBackgroundUploadSessionPrefix stringByAppendingString:self.identifier];
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{

    
    uexUploadInfo *info = [uexUploadInfo cachedInfoWithIdentifier:self.identifier];
    if (!info) {
        return;
    }
    if (error) {
        info.status = uexUploaderStatusFailure;
    }else{
        info.percent = 100;
        info.status = uexUploaderStatusSuccess;
    }
    info.responseString = [[NSString alloc]initWithData:self.responseData encoding:NSUTF8StringEncoding];
    NSError *e = nil;
    [[NSFileManager defaultManager]removeItemAtPath:info.tempFilePath error:&e];
    if (e) {
        ACLogDebug(@"=> uexBackgroundUploader '%@' delete temp file at path '%@' ERROR : %@",info.identifier,info.tempFilePath,e.localizedDescription);
    }
    [info saveInQueue:_uexUploadMgrBackgroundOperationQueue completion:^{
        ACLogDebug(@" => uexBackgroundUploader '%@' save info complete.",info.identifier);
        [self invalidateSessionCancelingTasks:YES];
    }];
    

    [super URLSession:session task:task didCompleteWithError:error];

    
}

/**
 *  @bug 这个方法有时候会不执行!...
 */

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session{
    ACLogDebug(@"=> waiting for saving info");
    dispatch_barrier_async(_uexUploadMgrBackgroundOperationQueue, ^{
        ACLogDebug(@"=> uexBackgroundUploader '%@' notify background event finish",self.identifier);
        dispatch_async(dispatch_get_main_queue(), ^{
            [uexGlobalUploaderMgr notifyBackgroundUploaderSessionFinishingEventsForBackgroundWithIdentifier:self.identifier];
        });
    });
    [super URLSessionDidFinishEventsForBackgroundURLSession:session];
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
    [super URLSession:session didBecomeInvalidWithError:error];
    if (error) {
        ACLogDebug(@"=> uexBackgroundUploader '%@' session invalidate ERROR: %@",self.identifier,error.localizedDescription);
    }else{
        ACLogDebug(@"=> uexBackgroundUploader '%@' session invalidate SUCCESS",self.identifier);
    }
    [uexGlobalUploaderMgr notifyBackgroundUploaderSessionInvalidWithIdentifier:self.identifier];
}
@end

