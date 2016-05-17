/**
 *
 *	@file   	: uexUploadInfo.h  in EUExUploaderMgr
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
 
#import <Foundation/Foundation.h>
#import "uexBackgroundUploader.h"

@interface uexUploadInfo : NSObject<NSSecureCoding>

@property (nonatomic,strong)NSString *identifier;
@property (nonatomic,strong)NSString *serverURL;
@property (nonatomic,assign)NSInteger percent;
@property (nonatomic,assign)uint64_t totalSize;
@property (nonatomic,assign)uexUploaderStatus status;
@property (nonatomic,strong)NSDate *lastSaveDate;
@property (nonatomic,assign)uexUploaderType type;
//only for background info
@property (nonatomic,strong)NSString *tempFilePath;
@property (nonatomic,strong)NSDictionary *headers;
@property (nonatomic,strong)NSString *responseString;

+ (instancetype)infoForUploader:(__kindof uexUploader *)uploader;
+ (instancetype)cachedInfoWithIdentifier:(NSString *)identifier;

- (void)saveInQueue:(dispatch_queue_t)queue completion:(void (^)(void))completion;
- (void)save;
- (NSDictionary *)infoDict;




+ (void)clearInfoWithIdentifier:(NSString *)identifier;
+ (void)clearAll;
@end
