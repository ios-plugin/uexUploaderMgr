/**
 *
 *	@file   	: uexGlobalUploaderManager.m  in EUExUploaderMgr
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

#import "uexGlobalUploaderManager.h"
#import "uexBackgroundUploader.h"
#import "uexUploadInfo.h"
@interface uexGlobalUploaderManager()
@property (nonatomic,strong)NSMutableDictionary <NSString *,uexUploader *> *globalUploaders;
@property (nonatomic,strong)void (^backgroundSessionCompletionHandler)(void);
@property (nonatomic,strong)NSString *backgroundSessionHandlerIdentifier;
@end

static NSString *const kBackgroundIdentifiersKey = @"uexUploaderMgrBackgroundUploaderIdentifiers";
static NSMutableArray *backgroundIdentifiers;


@implementation uexGlobalUploaderManager

+ (void)initialize{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        backgroundIdentifiers = [[[NSUserDefaults standardUserDefaults]arrayForKey:kBackgroundIdentifiersKey] mutableCopy];
        if (!backgroundIdentifiers) {
            backgroundIdentifiers = [NSMutableArray array];
        }
    });
}

+ (instancetype)sharedManager{
    static uexGlobalUploaderManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc]init];
    });
    return manager;
}




- (void)resumeBackgroundUploaders{
    _globalUploaders = [NSMutableDictionary dictionary];
    UEXLog(@"uexUploaderMgr updates background uploaders' status");
    for(NSString *identifier in backgroundIdentifiers){
        uexBackgroundUploader *uploader = [uexBackgroundUploader resumeWithInfo:[uexUploadInfo cachedInfoWithIdentifier:identifier]];
        if(uploader && uploader.status == uexUploaderStatusUploading){
            [_globalUploaders setValue:uploader forKey:identifier];
        }else{
            [backgroundIdentifiers removeObject:identifier];
        }
        
    }
    [self synchronizeBackgroundIdentifiers];
}


- (__kindof uexUploader *)uploaderWithIdentifier:(NSString *)identifier{
    return self.globalUploaders[identifier];
}

- (BOOL)isIdentifierValid:(NSString *)identifier{
    return identifier && identifier.length > 0 && ![self.globalUploaders.allKeys containsObject:identifier];
}

- (void)addGlobalUploader:(uexUploader *)uploader{
    if (![self isIdentifierValid:uploader.identifier] || uploader.type == uexUploaderTypeDefault) {
        UEXLog(@"=> uexUploader '%@' is NOT a global uploader!",uploader.identifier);
        return;
    }
    [self.globalUploaders setValue:uploader forKey:uploader.identifier];
    if ([uploader isKindOfClass:[uexBackgroundUploader class]]) {
        [backgroundIdentifiers addObject:uploader.identifier];
        [self synchronizeBackgroundIdentifiers];
    }
}




- (void)synchronizeBackgroundIdentifiers{
    [[NSUserDefaults standardUserDefaults]setValue:backgroundIdentifiers forKey:kBackgroundIdentifiersKey];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

- (void)handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler{
    if (![identifier hasPrefix:[uexBackgroundUploader sessionPrefix]]) {
        return;
    }
    UEXLog(@"uexUploaderMgr will handle background event");
    self.backgroundSessionCompletionHandler = completionHandler;
    self.backgroundSessionHandlerIdentifier = [identifier substringFromIndex:[uexBackgroundUploader sessionPrefix].length];
}


- (void)notifyBackgroundUploaderSessionFinishingEventsForBackgroundWithIdentifier:(NSString *)identifier{
    [self tryExecuteBackgroundHandlerWithIdentifier:identifier];
}

- (void)notifyBackgroundUploaderSessionInvalidWithIdentifier:(NSString *)identifier{
    [self tryExecuteBackgroundHandlerWithIdentifier:identifier];
    if ([self.globalUploaders objectForKey:identifier]) {
        [self.globalUploaders removeObjectForKey:identifier];
        [backgroundIdentifiers removeObject:identifier];
        [self synchronizeBackgroundIdentifiers];
    }
}

- (void)tryExecuteBackgroundHandlerWithIdentifier:(NSString *)identifier{
    if (self.backgroundSessionHandlerIdentifier && [self.backgroundSessionHandlerIdentifier isEqual:identifier]) {
        void (^tmpHandler)(void) = self.backgroundSessionCompletionHandler;
        self.backgroundSessionCompletionHandler = nil;
        self.backgroundSessionHandlerIdentifier = nil;
        tmpHandler();
    }
}



#pragma mark - uexUploaderDelegate
- (void)uexUploaderDidCompleteUploadTask:(uexUploader *)uploader{
    [[uexUploadInfo infoForUploader:uploader] save];
    if (![uploader isKindOfClass:[uexBackgroundUploader class]]) {
        //uexBackgroundUploader需要在session ivalidate之后再处理
        [self.globalUploaders removeObjectForKey:uploader.identifier];
        [[uexUploadInfo infoForUploader:uploader]save];
    }
    
    
}

- (void)uexUploaderDidUploadData:(uexUploader *)uploader{
    [[uexUploadInfo infoForUploader:uploader]save];
}


@end
