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
#import "uexGlobalUploaderManager.h"
#import "uexBackgroundUploader.h"
#import "uexGlobalUploaderManager.h"
#import "JSON.h"
#import "ACEUtils.h"
#import "uexUploadInfo.h"



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

- (instancetype)initWithBrwView:(EBrowserView *)eInBrwView
{
    self = [super initWithBrwView:eInBrwView];
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


#define UEX_STRING(x) ([self getStringValue:x])

- (void)createUploader:(NSMutableArray *)inArguments{
    __block NSNumber *result = @1;
    __block NSString *identifier = nil;
    @onExit{
        if (ACE_Available()) {
            [EUtility browserView:self.meBrwView
      callbackWithFunctionKeyPath:@"uexUploaderMgr.cbCreateUploader"
                        arguments:ACE_ArgsPack(identifier,@2,result)
                       completion:nil];
        }else{
            if (!identifier) {
                identifier = @"null";
            }else{
                identifier = [identifier JSONFragment];
            }
            NSString *jsStr = [NSString stringWithFormat:@"if(uexUploaderMgr.cbCreateUploader){uexUploaderMgr.cbCreateUploader(%@,%@,%@)}",identifier,@2,result];
            [EUtility brwView:self.meBrwView evaluateScript:jsStr];
        }
    };
    
    
    if([inArguments count] < 2){
        UEXLogParameterError();
        return;
    }
    identifier = UEX_STRING(inArguments[0]);
    NSString *serverURL = UEX_STRING(inArguments[1]);
    if (!identifier
        || ![uexGlobalUploaderMgr isIdentifierValid:identifier ]
        || [self.uploaders.allKeys containsObject:identifier]
        || !serverURL
        || ![serverURL.lowercaseString containsString:@"http"]) {
        UEXLogParameterError();
        return;
    }

    uexUploaderType type = uexUploaderTypeDefault;
    NSDictionary *ext = nil;
    if (inArguments.count > 2) {
        ext = [inArguments[2] JSONValue];
        if (![ext isKindOfClass:[NSDictionary class]]) {
            ext = nil;
        }
    }
    if(ext){
        if (ext[@"type"]) {
            type = [ext[@"type"] integerValue];
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
    
}

- (void)closeUploader:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        UEXLogParameterError();
        return;
    }
    NSString *identifier = UEX_STRING(inArguments[0]);
    __kindof uexUploader *uploader = nil;
    uploader = [uexGlobalUploaderMgr uploaderWithIdentifier:identifier];
    if (!uploader) {
        uploader = self.uploaders[identifier];
    }
    [uploader cancelUpload];
}

- (void)setHeaders:(NSMutableArray *)inArguments{
    if([inArguments count] < 2){
        UEXLogParameterError();
        return;
    }
    NSString *identifier = UEX_STRING(inArguments[0]);
    id info = [inArguments[1] JSONValue];
    if(!identifier || !info || ![info isKindOfClass:[NSDictionary class]]){
        UEXLogParameterError();
        return;
    }
    __kindof uexUploader *uploader = [self uploaderForIdentifier:identifier];
    [uploader setHeaders:info];
}


- (void)uploadFile:(NSMutableArray *)inArguments{
    if([inArguments count] < 3){
        return;
    }
    NSString *identifier = UEX_STRING(inArguments[0]);
    NSString *filePath = [self absPath:UEX_STRING(inArguments[1])];
    NSString *field = UEX_STRING(inArguments[2]);
    if (!identifier || !filePath || !field) {
        UEXLogParameterError();
        return;
    }
    NSInteger quality = inArguments.count > 3 ? [inArguments[3] integerValue] : 0;
    CGFloat maxWidth = inArguments.count > 4 ? [inArguments[4] floatValue] : 0;
    __kindof uexUploader *uploader = [self uploaderForIdentifier:identifier];
    [uploader appendDataWithFilePath:filePath field:field editingImageWithScaledWidth:maxWidth compressLevel:quality];
    [uploader startUpload];
}

- (void)appendFileData:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        UEXLogParameterError();
        return;
    }
    id info = [inArguments[0] JSONValue];
    if(!info || ![info isKindOfClass:[NSDictionary class]]){
        UEXLogParameterError();
        return;
    }

    NSString *identifier = UEX_STRING(info[@"id"]);
    NSString *filePath = [self absPath:UEX_STRING(info[@"filePath"])];
    NSString *field = UEX_STRING(info[@"field"]);
    NSInteger quality = [info[@"quality"] integerValue];
    CGFloat maxWidth = [info[@"maxWidth"] floatValue];
    if (!identifier || !filePath || !field) {
        UEXLogParameterError();
        return;
    }
    __kindof uexUploader *uploader = [self uploaderForIdentifier:identifier];
    [uploader appendDataWithFilePath:filePath field:field editingImageWithScaledWidth:maxWidth compressLevel:quality];
}

- (void)startUploader:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        UEXLogParameterError();
        return;
    }
     NSString *identifier = UEX_STRING(inArguments[0]);
    if (!identifier) {
        UEXLogParameterError();
        return;
    }
    __kindof uexUploader *uploader = [self uploaderForIdentifier:identifier];
    [uploader startUpload];
}
- (void)observeUploader:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        UEXLogParameterError();
        return;
    }
    NSString *identifier = UEX_STRING(inArguments[0]);
    if (!identifier) {
        UEXLogParameterError();
        return;
    }
    __kindof uexUploader *uploader = [self uploaderForIdentifier:identifier];
    [uploader setObserver:self.meBrwView];
}
- (NSString *)getInfo:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        UEXLogParameterError();
        return nil;
    }
    NSString *identifier = UEX_STRING(inArguments[0]);
    if (!identifier) {
        UEXLogParameterError();
        return nil;
    }
    uexUploadInfo *info = [uexUploadInfo cachedInfoWithIdentifier:identifier];
    if (!info) {
        return nil;
    }
    return [info infoDict].JSONFragment;
}

- (void)setDebugMode:(NSMutableArray *)inArguments{
    if([inArguments count] < 1){
        UEXLogParameterError();
        return;
    }
    [uexUploadHelper setDebugEnable:[inArguments[0] boolValue]];
}


- (__kindof uexUploader *)uploaderForIdentifier:(NSString *)identifier{
    __kindof uexUploader *uploader = nil;
    uploader = [uexGlobalUploaderMgr uploaderWithIdentifier:identifier];
    if (!uploader) {
        uploader = self.uploaders[identifier];
    }
    return uploader;
}


- (NSString *)getStringValue:(id)obj{
    if ([obj isKindOfClass:[NSString class]]) {
        return obj;
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj stringValue];
    }
    return nil;
}

@end



