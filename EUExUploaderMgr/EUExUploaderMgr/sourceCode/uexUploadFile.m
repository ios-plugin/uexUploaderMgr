/**
 *
 *	@file   	: uexUploadFile.m  in EUExUploaderMgr
 *
 *	@author 	: CeriNo 
 * 
 *	@date   	: Created on 16/5/12.
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

#import "uexUploadFile.h"
#import <AssetsLibrary/AssetsLibrary.h>
@interface uexUploadFile(){
    dispatch_semaphore_t _lock;
}


#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_lock)

@property (nonatomic,strong,readwrite)NSString *MIMEType;
@property (nonatomic,strong,readwrite)NSString *fileName;
@property (nonatomic,strong)NSString *filePath;
@property (nonatomic,strong)UIImage *imageToEdit;
@property (nonatomic,strong)NSData *editedData;
@end;


@implementation uexUploadFile


- (instancetype)initWithFilePath:(NSString *)filePath
{
    self = [super init];
    if (self) {
        _filePath = filePath;
        _MIMEType = [uexUploadHelper MIMETypeForPathExtension:filePath.pathExtension];
        _fileName = filePath.lastPathComponent;
        _lock = dispatch_semaphore_create(1);
        if([filePath hasPrefix:@"assets-library"]){
            [self fetchAssetImageWithURL:[NSURL URLWithString:filePath]];
        }
    }
    return self;
}

- (void)editImageWithScaledWidth:(CGFloat)scaledWidth compressLevel:(NSInteger)compressLevel{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Lock();
        if (!self.imageToEdit) {
            self.imageToEdit = [UIImage imageWithContentsOfFile:self.filePath];
        }
        if(!self.imageToEdit){
            Unlock();
            return;
        }
        CGFloat targetWidth = scaledWidth >= self.imageToEdit.size.width ? self.imageToEdit.size.width : scaledWidth;
        CGFloat targetHeight = targetWidth / self.imageToEdit.size.width * self.imageToEdit.size.height;
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(targetWidth, targetHeight), NO, self.imageToEdit.scale);
        [self.imageToEdit drawInRect:CGRectMake(0, 0, targetWidth, targetHeight)];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        CGFloat quality = 1;
        if (compressLevel > 0) {
            switch (compressLevel) {
                case 1:{
                    quality = 0.75;
                    break;
                }
                case 2:{
                    quality = 0.5;
                    break;
                }
                case 3:{
                    quality = 0.25;
                    break;
                }
                default:{
                    quality = 0.25;
                    break;
                }
            }
        }
        
        self.editedData = UIImageJPEGRepresentation(image, quality);
        self.MIMEType = [uexUploadHelper MIMETypeForPathExtension:@"jpg"];
        Unlock();
    });
}


- (void)fetchAssetImageWithURL:(NSURL *)URL{
    if (!URL) {
        return;
    }
   
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Lock();
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc]init];
        [library assetForURL:URL resultBlock:^(ALAsset *asset) {
            ALAssetRepresentation *representation = [asset defaultRepresentation];
            self.imageToEdit = [UIImage imageWithCGImage:representation.fullResolutionImage];
            self.MIMEType = [uexUploadHelper MIMETypeForPathExtension:@"jpg"];
            self.fileName = representation.filename;
            Unlock();
        } failureBlock:^(NSError *error) {
            UEXLog(@"fetch asset image error:%@",error.localizedDescription);
            Unlock();
        }];
    });
}
- (NSData *)fileData{
    NSData *fileData = nil;
    Lock();
    if (self.editedData) {
        fileData = self.editedData;
    }else{
        fileData = [NSData dataWithContentsOfFile:self.filePath];
    }
    Unlock();
    return fileData;
}
@end
