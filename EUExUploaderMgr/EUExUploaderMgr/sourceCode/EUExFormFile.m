//
//  EUExFormFile.m
//  WebKitCorePlam
//
//  Created by AppCan on 11-10-21.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "EUExFormFile.h"
#import "EUExBase.h"
#import "EUtility.h"
#import "EUExBaseDefine.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "EUExUploaderMgr.h"
@implementation EUExFormFile
@synthesize targetAddress,opid;
@synthesize filePath,isUploading;
@synthesize euexObj,receiveString;
@synthesize imageData;
@synthesize aRequest;
@synthesize aHeaderDict;
-(void)getJPEGFromAssetForURL:(NSURL *)url upload:(ASIFormDataRequest*)request name:(NSString *)inName{
	
    ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
    [assetslibrary assetForURL:url
				   resultBlock: ^(ALAsset *myasset) {
					   ALAssetRepresentation *rep = [myasset defaultRepresentation];
					   Byte *buf = malloc([rep size]);  
					   NSError *err = nil;
					   NSUInteger bytes = [rep getBytes:buf fromOffset:0LL 
												 length:[rep size] error:&err];
					   if (err || bytes == 0) {
						   // Are err and bytes == 0 redundant? Doc says 0 return means 
						   // error occurred which presumably means NSError is returned
						   PluginLog(@"error from getBytes: %@", err);
						   self.imageData = nil;
                           free(buf);
						   return;
					   } 
					   self.imageData = [NSData dataWithBytesNoCopy:buf length:[rep size] 
													   freeWhenDone:YES];
					   if (imageData) {
						   NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
						   [formatter setDateFormat:@"MM_dd_HH_mm_ss"];
						   NSString *jpgName = [NSString stringWithFormat:@"%@.jpg",[formatter stringFromDate:[NSDate date]]];
						   [request addData:imageData withFileName:jpgName andContentType:@"image/jpeg" forKey:inName];
						   filesize = [imageData length];
						   [request startAsynchronous];
					   } 
					   // YES means free malloc'ed buf that backs this when deallocated
				   }
				  failureBlock: ^(NSError *err) {
                      //
				  }];
    [assetslibrary release];
}

-(long)getFileLength:(NSString *)fileName{
	NSFileManager *fmanager = [NSFileManager defaultManager];
	NSDictionary *dic = [fmanager attributesOfItemAtPath:fileName error:nil];	
	NSNumber *fileSize = [dic objectForKey:NSFileSize];
	
	long sum = [fileSize longLongValue];
	return sum;
}

-(void)uploadingWithName:(NSString *)inName{
	NSString *ulPath = self.filePath; 
	NSURL *url = [NSURL URLWithString:self.targetAddress];
	self.aRequest = [ASIFormDataRequest requestWithURL:url];
	[aRequest setDelegate:self];
	[aRequest setUploadProgressDelegate:self];
    [aRequest setTimeOutSeconds:5*60*1000];
    if (aHeaderDict&&[aHeaderDict isKindOfClass:[NSMutableDictionary class]]) {
        [aRequest setRequestHeaders:aHeaderDict];
    }
    aRequest.defaultResponseEncoding = NSUTF8StringEncoding;
	if ([ulPath hasPrefix:@"assets-library"]) {
		NSURL *fileUrl = [NSURL URLWithString:ulPath];
		[self getJPEGFromAssetForURL:fileUrl upload:aRequest name:inName];
	}else {
		filesize = [self getFileLength:ulPath];
		if (![[NSFileManager defaultManager] fileExistsAtPath:ulPath]) {
            if (euexObj) {
                [euexObj jsFailedWithOpId:0 errorCode:1200202 errorDes:UEX_ERROR_DESCRIBE_FILE_EXIST];
            }
			return;
		}
		[aRequest setFile:ulPath forKey:inName];
		[aRequest startAsynchronous];
	}
}
-(void)request:(ASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders{
}

-(void)request:(ASIHTTPRequest *)request didSendBytes:(long long)bytes{
	self.receiveString = [request responseString];
	upldsize  += bytes;
	int perc = upldsize*100/filesize;
	if (perc>100) {
		perc = 100;
	}
    if (euexObj) {
        [euexObj uexOnUpLoadWithOpId:[self.opid intValue] fileSize:filesize percent:perc serverPath:@"" status:UEX_UPLOAD_UPLOADING];
    }
	
}

-(void)requestFinished:(ASIHTTPRequest *)request{
	NSFileManager *fmanager = [NSFileManager defaultManager];
	NSString *tempPath = [EUtility  documentPath:@"imgtemp"];
	if ([fmanager fileExistsAtPath:tempPath]) {
		[fmanager removeItemAtPath:tempPath error:nil];
	}
	self.receiveString = [request responseString];
    if (euexObj) {
        [euexObj uexOnUpLoadWithOpId:[self.opid intValue]fileSize:filesize percent:100 serverPath:receiveString status:UEX_UPLOAD_FINISH];
    }
	//[euexObj.formDict removeObjectForKey:self.opid];
}

-(void)requestFailed:(ASIHTTPRequest *)request{
	//	[BUtility writeLog:@"fail"];
    if (euexObj) {
        [euexObj uexOnUpLoadWithOpId:[self.opid intValue] fileSize:0 percent:0 serverPath:@"" status:UEX_UPLOAD_FAIL];
        [euexObj.formDict removeObjectForKey:self.opid];
    }
}

-(void)dealloc{
    
    if (self.aHeaderDict) {
        self.aHeaderDict = nil;
    }
	if (aRequest) {
		[aRequest release];
		aRequest = nil;
	}
	if (imageData) {
        self.imageData = nil;
	}
	if (targetAddress) {
        self.targetAddress = nil;
	}
	if (receiveString) {
        self.receiveString = nil;
	}
	if (filePath) {
        self.filePath = nil;
	}
	if (opid) {
        self.opid = nil;
	}
	[super dealloc];
}
@end
