/**
 *
 *	@file   	: uexUploader.h  in EUExUploaderMgr
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


#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
@class EUExUploaderMgr;
@class EBrowserView;

typedef NS_ENUM(NSInteger,uexUploaderStatus) {
    uexUploaderStatusUploading = 0,
    uexUploaderStatusSuccess,
    uexUploaderStatusFailure
};

typedef NS_ENUM(NSInteger,uexUploaderType){
    uexUploaderTypeDefault = 0,
    uexUploaderTypeGlobal,
    uexUploaderTypeBackground
};

@class uexUploadFile;
@class uexUploader;

@protocol uexUploaderDelegate <NSObject>
@optional
- (void)uexUploaderDidUploadData:(uexUploader *)uploader;
- (void)uexUploaderDidCompleteUploadTask:(uexUploader *)uploader;
@end


@interface uexUploader : NSObject
@property (nonatomic,strong)NSString *identifier;
@property (nonatomic,weak)EBrowserView *observer;
@property (nonatomic,assign)uexUploaderType type;

@property (nonatomic,strong)NSDictionary *headers;
@property (nonatomic,weak)EUExUploaderMgr *euexObj;
@property (nonatomic,strong)NSMutableDictionary<NSString *,uexUploadFile *> *files;
@property (nonatomic,strong)NSURLSessionDataTask *task;
@property (nonatomic,strong)NSString *serverURL;
@property (nonatomic,assign)NSInteger percent;
@property (nonatomic,assign)uint64_t totalSize;
@property (nonatomic,assign)uexUploaderStatus status;
@property (nonatomic,strong)__kindof AFURLSessionManager *sessionManager;
@property (nonatomic,strong)NSString *responseString;

- (void)onStatusCallback;



- (void)setHeaders:(NSDictionary *)headers;
- (instancetype)initWithIdentifier:(NSString *)identidier serverURL:(NSString *)serverURL euexObj:(EUExUploaderMgr *)euexObj;




- (void)appendDataWithFilePath:(NSString *)filePath field:(NSString *)field editingImageWithScaledWidth:(CGFloat)scaledWidth
                      compressLevel:(NSInteger)compressLevel;
- (void)startUpload;
- (void)cancelUpload;





@end
