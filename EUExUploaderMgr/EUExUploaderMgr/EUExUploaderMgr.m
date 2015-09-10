//
//  EUExUploaderMgr.m
//  AppCan
//
//  Created by AppCan on 11-10-18.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "EUExUploaderMgr.h"
#import "EUtility.h"
#import "EUExBaseDefine.h"
#import "EUExFormFile.h"
#import "JSON.h"

@implementation EUExUploaderMgr
@synthesize formDict;

-(id)initWithBrwView:(EBrowserView *) eInBrwView{	
	if (self = [super initWithBrwView:eInBrwView]) {
		formDict = [[NSMutableDictionary alloc] initWithCapacity:10];
	}
 	return self;
}
 
-(void)dealloc{
 	if (formDict) {
		NSArray *arr = [formDict allValues];
		for(EUExFormFile *formObj in arr){
			if (formObj) {
                
				[formObj release];
				formObj = nil;
			}
		}
		[formDict release];
		formDict = nil;
	}
	[super dealloc];
}

//设置头
-(void)setHeaders:(NSMutableArray *)inArguments{
    
    if ([inArguments isKindOfClass:[NSMutableArray class]] && [inArguments count]>=2) {
        NSString *inOpId = [inArguments objectAtIndex:0];
        NSString *inJsonHeaderStr = [inArguments objectAtIndex:1];
        
        EUExFormFile *uploadObj = [formDict objectForKey:inOpId];
        if (uploadObj) {
            NSMutableDictionary *headerDict = [inJsonHeaderStr JSONValue];
            if (headerDict && [headerDict isKindOfClass:[NSMutableDictionary class]]) {
                [uploadObj setAHeaderDict:headerDict];
            }
        }
    }
}

-(void)createUploader:(NSMutableArray *)inArguments{	
	NSString *inOpId = [inArguments objectAtIndex:0];
	NSString *inUrl = [inArguments objectAtIndex:1];
//一个页面不能重复创建相同的id的上传对象
	if ([formDict objectForKey:inOpId]) {
		[self jsSuccessWithName:@"uexUploaderMgr.cbCreateUploader" opId:[inOpId intValue] dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
		return;
	}
//目标地址为空，直接返回，报参数错误
	if (inUrl==nil||![inUrl hasPrefix:@"http"]) {
		[self jsFailedWithOpId:0 errorCode:1200101 errorDes:UEX_ERROR_DESCRIBE_ARGS];
		return;
	}
//初始化上传对象
	EUExFormFile *uploadObj = [[EUExFormFile alloc] init];
	uploadObj.targetAddress = inUrl;
	uploadObj.opid = inOpId;
	uploadObj.euexObj = self;
	uploadObj.isUploading = YES;
	[formDict setObject:uploadObj forKey:inOpId];
	[self jsSuccessWithName:@"uexUploaderMgr.cbCreateUploader" opId:[inOpId intValue] dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
}

-(void)closeUploader:(NSMutableArray *)inArguments{
	NSString *inOpId = [inArguments objectAtIndex:0];
	if (formDict&&[formDict count]>0) {
		EUExFormFile *uploadObj = (EUExFormFile*)[formDict objectForKey:inOpId];
		if (uploadObj) {
			if (uploadObj.aRequest) {
				[uploadObj.aRequest cancel];
			}
		[formDict removeObjectForKey:inOpId];
		}
	}
}
-(UIImage*)imageByScalingAndCroppingForSize:(UIImage *)sourceImage width:(float)destWith
{
    UIImage *newImage = nil;      
	CGFloat srcWidth = sourceImage.size.width;
	CGFloat srcHeight = sourceImage.size.height;
	CGFloat targetWidth;
	CGFloat targetHeight;
//	if (srcHeight<960.0&&srcWidth<640.0) {
//		targetHeight = srcHeight;
//		targetWidth = srcWidth;
//	}else if (srcHeight<960.0&&srcWidth>640.0) {
//		targetHeight = (srcHeight*640.0)/(srcWidth*1.0);
//		targetWidth = 640.0;
//	}else {
//		targetHeight = 960.0;
//		targetWidth = (960.0*srcWidth)/(srcHeight*1.0);
//	}
    if (srcWidth<= destWith) {
        targetWidth = srcWidth;
        targetHeight = srcHeight;
    }else {
        targetWidth = destWith;
        targetHeight = (srcHeight*destWith)/(srcWidth*1.0);
    }
    CGSize targetSize = CGSizeMake(targetWidth, targetHeight);
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(sourceImage.size, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / srcWidth;
        CGFloat heightFactor = targetHeight / srcHeight;
        
        if (widthFactor > heightFactor)
            scaleFactor = widthFactor; // scale to fit height
        else
            scaleFactor = heightFactor; // scale to fit width
        scaledWidth  = srcWidth * scaleFactor;
        scaledHeight = srcHeight * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else
            if (widthFactor < heightFactor)
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
    }
    UIGraphicsBeginImageContext(targetSize); // this will crop
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil)
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
} 

-(void)uploadFile:(NSMutableArray *)inArguments{
    
	NSString *inOpId = [inArguments objectAtIndex:0];
	NSString *inFilePath = [inArguments objectAtIndex:1];
	NSString *inName = [inArguments objectAtIndex:2];
    NSString *inIsCompress = nil;
    
    if([inArguments count] >3){
       inIsCompress = [inArguments objectAtIndex:3];
    }
    float widthLimit = 640;
    if ([inArguments count]>4) {
        widthLimit = [[inArguments objectAtIndex:4] floatValue];
    }
	inFilePath = [super absPath:inFilePath]; 
	NSString *suffixStr = [inFilePath lastPathComponent];
	NSString *lowStrPath = [suffixStr lowercaseString];
    int conpressLevel = [inIsCompress intValue];
	if (conpressLevel>0) {
		if ([lowStrPath hasSuffix:@"png"]||[lowStrPath hasSuffix:@"jpg"]||[lowStrPath hasSuffix:@"jpeg"]) {
			UIImage *upImg = [UIImage imageWithData:[NSData dataWithContentsOfFile:inFilePath]];
			if (upImg) {
				UIImage *newImage = [self imageByScalingAndCroppingForSize:upImg width:widthLimit];
                NSData *newImageData = nil;
                switch (conpressLevel) {
                    case 1:
                        newImageData = UIImageJPEGRepresentation(newImage, 1.0);
                        break;
                    case 2:
                        newImageData = UIImageJPEGRepresentation(newImage, 0.75);
                        break;
                    case 3:
                        newImageData = UIImageJPEGRepresentation(newImage, 0.5);
                        break;
                    case 4:
                       newImageData = UIImageJPEGRepresentation(newImage, 0.25);
                        break;
                    default:
                        newImageData = UIImageJPEGRepresentation(newImage, 0.5);
                }
				if (newImageData!=nil) {
					NSFileManager *fmanager = [NSFileManager defaultManager];
					NSString *tempImgPath = [EUtility documentPath:@"imgtemp"];
					if (![fmanager fileExistsAtPath:tempImgPath]) {
						[fmanager createDirectoryAtPath:tempImgPath withIntermediateDirectories:YES attributes:nil error:nil];
					}
					NSString *tempImgName =[tempImgPath stringByAppendingPathComponent:lowStrPath];
					if ([fmanager fileExistsAtPath:tempImgName]) {
						[fmanager removeItemAtPath:tempImgName error:nil];
					}
					[fmanager createFileAtPath:tempImgName contents:nil attributes:nil];
					BOOL succ = [newImageData writeToFile:tempImgName atomically:YES];
					if (succ) {
						PluginLog(@"write tempimage success");
						inFilePath = tempImgName;
				}
			  }
			}
		}
	}
	EUExFormFile *uploadObj = [formDict objectForKey:inOpId];
	if (uploadObj) {
		uploadObj.filePath = inFilePath;
		if (uploadObj.isUploading == YES) {
			uploadObj.isUploading = NO;
			[uploadObj uploadingWithName:inName];
		}
	}else {
		[self jsFailedWithOpId:0 errorCode:1200204 errorDes:UEX_ERROR_DESCRIBE_FILE_OPEN];
	}
}
 
-(void)uexOnUpLoadWithOpId:(int)inOpId fileSize:(int)inFileSize percent:(int)inPercent serverPath:(NSString *)inServerPath status:(int)inStatus{
 	NSString *jsStr = [NSString stringWithFormat:@"if(uexUploaderMgr.onStatus!=null){uexUploaderMgr.onStatus(%d,%d,%d,\'%@\',%d)}",inOpId,inFileSize,inPercent,inServerPath,inStatus];
	[meBrwView stringByEvaluatingJavaScriptFromString:jsStr];
	
}

-(void)clean{
	if (formDict) {
		NSArray *arr = [formDict allValues];
		for(EUExFormFile *form in arr){
			if (form.aRequest) {
                [form.aRequest setDelegate:nil];
				[form.aRequest cancel];
			}
		}
		[formDict removeAllObjects];
	}
    if (meBrwView) {
        meBrwView = nil;
    }
}
 
- (void)stopNetService {
	
}
@end
