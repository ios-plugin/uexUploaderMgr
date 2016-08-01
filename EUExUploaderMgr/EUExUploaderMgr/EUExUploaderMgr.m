/**
 *
 *	@file   	: EUExUploaderMgr.m  in EUExUploaderMgr
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

#import "EUExUploaderMgr.h"
#import <AFNetworking/AFNetworking.h>
#import <AppCanKit/ACEXTScope.h>
#import "uexGlobalUploaderManager.h"
#import "uexBackgroundUploader.h"
#import "uexGlobalUploaderManager.h"


#import "uexUploadInfo.h"

#define UEX_TRUE @(YES)
#define UEX_FALSE @(NO)


@interface EUExUploaderMgr()

@property (nonatomic,strong)NSMutableDictionary<NSString *,uexUploader *>*uploaders;
@end

@implementation EUExUploaderMgr

+ (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler{
    [uexGlobalUploaderMgr handleEventsForBackgroundURLSession:identifier completionHandler:completionHandler];
}


+ (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [uexGlobalUploaderMgr resumeBackgroundUploaders];//更新后台上传任务的状态
    return YES;
}


- (instancetype)initWithWebViewEngine:(id<AppCanWebViewEngineObject>)engine
{
    self = [super initWithWebViewEngine:engine];
    if (self) {
        _uploaders = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)clean{
    [self.uploaders enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, uexUploader * _Nonnull obj, BOOL * _Nonnull stop) {
        [obj cancelUpload];
    }];
    [self.uploaders removeAllObjects];
}

- (void)uexUploaderDidUploadData:(uexUploader *)uploader{
    
}


- (void)uexUploaderDidCompleteUploadTask:(uexUploader *)uploader{
    [self.uploaders removeObjectForKey:uploader.identifier];
}


#ifdef DEBUG

- (void)test:(NSMutableArray *)inArguments{
    NSString *identifier = @"myID2";
    NSString *serverURL = @"http://192.168.1.4:45678/upload";
    NSString *filePath = [self absPath:@"res://zlackApple.pdf"];
    
    

    
    uexBackgroundUploader *uploader = [[uexBackgroundUploader alloc]initWithIdentifier:identifier serverURL:serverURL euexObj:self];
    uploader.type = uexUploaderTypeBackground;
    [uploader appendDataWithFilePath:filePath field:@"myField1" editingImageWithScaledWidth:0 compressLevel:0] ;
    [uploader appendDataWithFilePath:filePath field:@"myField2" editingImageWithScaledWidth:0 compressLevel:0];
    //[self.uploaders setObject:uploader forKey:identifier];
    [uexGlobalUploaderMgr addGlobalUploader:uploader];
    [uploader startUpload];
    

}

#endif

- (NSString *)create:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    NSString *identifier = stringArg(info[@"id"]) ?: [NSUUID UUID].UUIDString;
    NSString *serverURL = stringArg(info[@"url"]);
    NSNumber *typeNum = numberArg(info[@"type"]);
    uexUploaderType type = typeNum ? typeNum.integerValue : uexUploaderTypeDefault;
    if (!identifier
        || ![uexGlobalUploaderMgr isIdentifierValid:identifier ]
        || [self.uploaders.allKeys containsObject:identifier]
        || !serverURL
        || ![serverURL.lowercaseString containsString:@"http"]) {
        UEXLogParameterError();
        return nil;
    }
    switch (type) {
        case uexUploaderTypeDefault: {
            uexUploader *uploader = [[uexUploader alloc]initWithIdentifier:identifier serverURL:serverURL euexObj:self];
            [self.uploaders setObject:uploader forKey:identifier];
            break;
        }
        case uexUploaderTypeGlobal: {
            uexUploader *uploader = [[uexUploader alloc]initWithIdentifier:identifier serverURL:serverURL euexObj:self];
            uploader.type = uexUploaderTypeGlobal;
            [uexGlobalUploaderMgr addGlobalUploader:uploader];
            break;
        }
        case uexUploaderTypeBackground: {
            uexBackgroundUploader *uploader = [[uexBackgroundUploader alloc]initWithIdentifier:identifier serverURL:serverURL euexObj:self];
            [uexGlobalUploaderMgr addGlobalUploader:uploader];
            break;
        }
    }
    return identifier;
}


- (NSNumber *)createUploader:(NSMutableArray *)inArguments{
    __block NSNumber *result = @1;
    ACArgsUnpack(NSString *identifier,NSString *serverURL,NSDictionary *ext) = inArguments;
    @onExit{
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexUploaderMgr.cbCreateUploader" arguments:ACArgsPack(identifier,@2,result)];
    };
    
    if (!identifier
        || ![uexGlobalUploaderMgr isIdentifierValid:identifier ]
        || [self.uploaders.allKeys containsObject:identifier]
        || !serverURL
        || ![serverURL.lowercaseString containsString:@"http"]) {
        UEXLogParameterError();
        return UEX_FALSE;
    }

    uexUploaderType type = uexUploaderTypeDefault;
    if(ext){
        NSNumber *typeNum = numberArg(ext[@"type"]);
        if (typeNum) {
            type = [typeNum integerValue];
        }
    }
    switch (type) {
        case uexUploaderTypeDefault: {
            uexUploader *uploader = [[uexUploader alloc]initWithIdentifier:identifier serverURL:serverURL euexObj:self];
            [self.uploaders setObject:uploader forKey:identifier];
            break;
        }
        case uexUploaderTypeGlobal: {
            uexUploader *uploader = [[uexUploader alloc]initWithIdentifier:identifier serverURL:serverURL euexObj:self];
            uploader.type = uexUploaderTypeGlobal;
            [uexGlobalUploaderMgr addGlobalUploader:uploader];
            break;
        }
        case uexUploaderTypeBackground: {
            uexBackgroundUploader *uploader = [[uexBackgroundUploader alloc]initWithIdentifier:identifier serverURL:serverURL euexObj:self];
            [uexGlobalUploaderMgr addGlobalUploader:uploader];
            break;
        }
    }
    result = @0;
    return UEX_TRUE;
}

- (NSNumber *)closeUploader:(NSMutableArray *)inArguments{

    ACArgsUnpack(NSString *identifier) = inArguments;
    if (!identifier || identifier.length == 0) {
        UEXLogParameterError();
        return UEX_FALSE;
    }

    __kindof uexUploader *uploader = nil;
    uploader = [uexGlobalUploaderMgr uploaderWithIdentifier:identifier];
    if (!uploader) {
        uploader = self.uploaders[identifier];
    }

    [uploader cancelUpload];
    return UEX_TRUE;
}

- (NSNumber *)setHeaders:(NSMutableArray *)inArguments{

    ACArgsUnpack(NSString *identifier, NSDictionary *info) = inArguments;
    

    if(!identifier || !info){
        UEXLogParameterError();
        return UEX_FALSE;
    }
    uexUploader *uploader = [self uploaderForIdentifier:identifier];
    [uploader setHeaders:info];
    return  UEX_TRUE;
}


- (void)uploadFile:(NSMutableArray *)inArguments{

    ACArgsUnpack(NSString *identifier,NSString *filePath,NSString *field,NSNumber *qualityNum,NSNumber *maxWidthNum) = inArguments;
    ACJSFunctionRef *cb = JSFunctionArg(inArguments.lastObject);
    filePath = [self absPath:filePath];

    if (!identifier || !filePath || !field) {
        UEXLogParameterError();
        return;
    }
    NSInteger quality = [qualityNum integerValue];
    CGFloat maxWidth = [maxWidthNum floatValue];
    __kindof uexUploader *uploader = [self uploaderForIdentifier:identifier];
    
    uploader.cb = cb;
    [uploader appendDataWithFilePath:filePath field:field editingImageWithScaledWidth:maxWidth compressLevel:quality];
    [uploader startUpload];
}

- (NSNumber *)appendFileData:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSDictionary *info) = inArguments;
    
    NSString *identifier = stringArg(info[@"id"]);
    NSString *filePath = [self absPath:stringArg(info[@"filePath"])];
    NSString *field = stringArg(info[@"field"]);
    NSInteger quality = [info[@"quality"] integerValue];
    CGFloat maxWidth = [info[@"maxWidth"] floatValue];
    if (!identifier || !filePath || !field) {
        UEXLogParameterError();
        return UEX_FALSE;
    }
    __kindof uexUploader *uploader = [self uploaderForIdentifier:identifier];
    [uploader appendDataWithFilePath:filePath field:field editingImageWithScaledWidth:maxWidth compressLevel:quality];
    return  UEX_TRUE;
}

- (void)startUploader:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSString *identifier,ACJSFunctionRef *cb) = inArguments;
    
    if (!identifier) {
        UEXLogParameterError();
        return;
    }
    __kindof uexUploader *uploader = [self uploaderForIdentifier:identifier];
    uploader.cb = cb;
    [uploader startUpload];
}
- (NSNumber *)observeUploader:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSString *identifier) = inArguments;
    if (!identifier) {
        UEXLogParameterError();
        return UEX_FALSE;
    }
    __kindof uexUploader *uploader = [self uploaderForIdentifier:identifier];
    [uploader setObserver:self.webViewEngine];
    return  UEX_TRUE;
}
- (NSDictionary *)getInfo:(NSMutableArray *)inArguments{
    ACArgsUnpack(NSString *identifier) = inArguments;
    if (!identifier) {
        UEXLogParameterError();
        return nil;
    }
    uexUploadInfo *info = [uexUploadInfo cachedInfoWithIdentifier:identifier];
    if (!info) {
        return nil;
    }
    return [info infoDict];
}

- (void)setDebugMode:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        UEXLogParameterError();
        return;
    }
    if ([inArguments[0] boolValue]) {
        ACLogSetGlobalLogMode(ACLogModeDebug);
    }else{
        ACLogSetGlobalLogMode(ACLogModeInfo);
    }
}


- (__kindof uexUploader *)uploaderForIdentifier:(NSString *)identifier{
    __kindof uexUploader *uploader = nil;
    uploader = [uexGlobalUploaderMgr uploaderWithIdentifier:identifier];
    if (!uploader) {
        uploader = self.uploaders[identifier];
    }
    return uploader;
}




@end



