/**
 *
 *	@file   	: uexUploadInfo.m  in EUExUploaderMgr
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

#import "uexUploadInfo.h"
#import "uexBackgroundUploader.h"

#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_lock)

#define classLock() dispatch_semaphore_wait(_classLock, DISPATCH_TIME_FOREVER)
#define classUnlock() dispatch_semaphore_signal(_classLock)



static dispatch_semaphore_t _classLock;
static NSMutableDictionary<NSString *,uexUploadInfo *> *_cacheDictionary;
static NSString *const kUexUploaderMgrPrivateInfoDictionaryKey = @"uexUploaderMgrPrivateInfoDictionary";
static NSString *_cacheFolderPath;

static NSTimeInterval kMinimumSaveInteval = 5.0;
@interface uexUploadInfo(){
    dispatch_semaphore_t _lock;
}


@end

@implementation uexUploadInfo


+ (void)initialize{
    if (self.class == [uexUploadInfo class]) {
        _classLock = dispatch_semaphore_create(1);
        _cacheDictionary = [NSMutableDictionary dictionary];
        _cacheFolderPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]stringByAppendingPathComponent:@"uexUploaderMgrInfoCache"];
        [self createCacheFolder];
        
    }
}

- (void)setupLock{
    if(!_lock){
        _lock = dispatch_semaphore_create(1);
    }
}

+ (instancetype)cachedInfoWithIdentifier:(NSString *)identifier{
    if (_cacheDictionary[identifier]) {
        return _cacheDictionary[identifier];
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = [self savePathForIdentifier:identifier];
    if (![fm fileExistsAtPath:path]) {
        return nil;
    }
    classLock();
    uexUploadInfo *info = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    [info setupLock];
    [_cacheDictionary setValue:info forKey:identifier];
    classUnlock();
    return info;
    
}

+ (instancetype)infoForUploader:(__kindof uexUploader *)uploader{
    uexUploadInfo *info = [self cachedInfoWithIdentifier:uploader.identifier];
    if (!info) {
        info = [[self alloc] init];
    }
    if (info) {
        info.identifier = uploader.identifier;
        info.type = uploader.type;
        info.serverURL = uploader.serverURL;
        info.totalSize = uploader.totalSize;
        info.status = uploader.status;
        info.percent = uploader.percent;
        
        info.responseString = uploader.responseString;
        if ([uploader isKindOfClass:[uexBackgroundUploader class]]) {
            uexBackgroundUploader *bgUploader = (uexBackgroundUploader *)uploader;
            info.tempFilePath = bgUploader.tempFilePath;
            info.headers = bgUploader.headers;
        }
        [info setupLock];
    }
    if (!_cacheDictionary[uploader.identifier]) {
        _cacheDictionary[uploader.identifier] = info;
    }
    return info;
}

- (void)saveInQueue:(dispatch_queue_t)queue completion:(void (^)(void))completion{
    if (self.status == uexUploaderStatusUploading && self.percent != 0 && self.percent != 100 && [[NSDate date]timeIntervalSinceDate:self.lastSaveDate] < kMinimumSaveInteval) {
        if (completion) {
            completion();
        }
        return;
    }
    if (!queue) {
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    dispatch_async(queue, ^{
        Lock();
        self.lastSaveDate = [NSDate date];
        NSString *path = [self.class savePathForIdentifier:self.identifier];
        NSFileManager *fm = [NSFileManager defaultManager];
        if([fm fileExistsAtPath:path]){
            [fm removeItemAtPath:path error:nil];
        }
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
        [data writeToFile:path atomically:YES];
        Unlock();
        if (completion) {
            completion();
        }
    });
}


- (void)save{
    [self saveInQueue:nil completion:nil];
}




- (NSDictionary *)infoDict{
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    [info setValue:@(self.status) forKey:@"status"];
    [info setValue:@(self.percent) forKey:@"percent"];
    [info setValue:self.serverURL forKey:@"serverURL"];
    [info setValue:self.responseString forKey:@"response"];
    BOOL isBackground = (self.type == uexUploaderTypeBackground);
    [info setValue:@(isBackground) forKey:@"isBackground"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *lastSaveDateStr = [dateFormatter stringFromDate:self.lastSaveDate];
    [info setValue:lastSaveDateStr forKey:@"lastSaveDate"];
    return [info copy];
}

+ (NSString *)savePathForIdentifier:(NSString *)identifier{
    return [_cacheFolderPath stringByAppendingPathComponent:identifier];
}

+ (void)clearInfoWithIdentifier:(NSString *)identifier{
    
    classLock();
    NSError *error = nil;
    [[NSFileManager defaultManager]removeItemAtPath:[self savePathForIdentifier:identifier] error:&error];
    if (error) {
        UEXLog(@"clear info %@ ERROR : %@",identifier,error.localizedDescription);
    }
    classUnlock();
}

+ (void)clearAll{
    classLock();
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    [fm removeItemAtPath:_cacheFolderPath error:&error];
    if (error) {
        UEXLog(@"clear ALL info ERROR : %@",error.localizedDescription);
    }
    [self createCacheFolder];
    classUnlock();
}

+ (void)createCacheFolder{
    if (![[NSFileManager defaultManager]fileExistsAtPath:_cacheFolderPath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager]createDirectoryAtPath:_cacheFolderPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            UEXLog(@"uexUploaderMgr create info cache path ERROR : %@",error.localizedDescription);
        }
    }
}
#pragma mark - NSSecurityCoding



+ (BOOL)supportsSecureCoding{
    return YES;
    
}

#define UEXEncodeObjectProperty(property) [aCoder encodeObject:self.property forKey:@metamacro_stringify(property)]
#define UEXEncodeNumberProperty(property) [aCoder encodeObject:@(self.property) forKey:@metamacro_stringify(property)]

- (void)encodeWithCoder:(NSCoder *)aCoder{
    UEXEncodeObjectProperty(identifier);
    UEXEncodeObjectProperty(serverURL);
    UEXEncodeObjectProperty(lastSaveDate);
    UEXEncodeObjectProperty(tempFilePath);
    UEXEncodeObjectProperty(headers);
    UEXEncodeObjectProperty(responseString);
    UEXEncodeNumberProperty(percent);
    UEXEncodeNumberProperty(status);
    UEXEncodeNumberProperty(totalSize);
    UEXEncodeNumberProperty(type);
    
}

#define UEXDecodeObjectProperty(property,cls) self.property = [aDecoder decodeObjectOfClass:[cls class] forKey:@metamacro_stringify(property)]
#define UEXDecodeNumberProperty(property,sel) self.property = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:@metamacro_stringify(property)] sel]

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        UEXDecodeObjectProperty(identifier, NSString);
        UEXDecodeObjectProperty(serverURL, NSString);
        UEXDecodeObjectProperty(lastSaveDate, NSDate);
        UEXDecodeObjectProperty(tempFilePath, NSString);
        UEXDecodeObjectProperty(headers, NSDictionary);
        UEXDecodeObjectProperty(responseString, NSString);
        UEXDecodeNumberProperty(percent, integerValue);
        UEXDecodeNumberProperty(status, integerValue);
        UEXDecodeNumberProperty(totalSize, longLongValue);
        UEXDecodeNumberProperty(type, integerValue);
    }
    return self;
}
@end
