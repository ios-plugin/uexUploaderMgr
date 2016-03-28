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
#import <CommonCrypto/CommonCrypto.h>
#import "EUExUploaderMgr.h"
#import "WWidget.h"
#import "EBrowserView.h"
#import "BUtility.h"
#import "WWidgetMgr.h"
#import "ACEBaseViewController.h"
#import "EBrowserController.h"

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

/**
 *  设置请求头的验证
 *
 *  @param inName nil
 */
-(NSString*)requestIsVerify{
    WWidget *curWgt = euexObj.meBrwView.mwWgt;
    NSString *time= [self getCurrentTS];
    NSString *appKey = @"";
    NSString *appId = @"";
    
    NSString *pluginStr = @"widget/plugin";
    if ([curWgt.indexUrl rangeOfString:pluginStr].length == [pluginStr length]) {
        WWidgetMgr *wgtMgr = euexObj.meBrwView.meBrwCtrler.mwWgtMgr;
        WWidget *mainWgt = [wgtMgr mainWidget];
        
        appId = mainWgt.appId;
        appKey = mainWgt.widgetOneId;
        
        
    } else {
        if (curWgt.appKey) {
            appKey = [NSString stringWithFormat:@"%@",curWgt.appKey];
        }else{
            appKey = [NSString stringWithFormat:@"%@",curWgt.widgetOneId];
        }
        appId = curWgt.appId;
    }
    
    self.verifyWithAppId = appId;
    
    NSString *str = [NSString stringWithFormat:@"%@:%@:%@",appId,appKey,time];
    str = [self md5:str];
    str = [NSString stringWithFormat:@"md5=%@;ts=%@;",str,time];
    return str;
}

-(void)uploadingWithName:(NSString *)inName{
    NSString *headerStr = nil;
	NSString *ulPath = self.filePath; 
	NSURL *url = [NSURL URLWithString:self.targetAddress];
	self.aRequest = [ASIFormDataRequest requestWithURL:url];
    //[self requestIsVerify];
	[aRequest setDelegate:self];
	[aRequest setUploadProgressDelegate:self];
    [aRequest setTimeOutSeconds:5*60*1000];
    //
    if ([self.targetAddress rangeOfString:@"https"].location != NSNotFound) {
        [aRequest setAuthenticationScheme:@"https"];
        [aRequest setValidatesSecureCertificate:NO];
    }
    
    if (aHeaderDict&&[aHeaderDict isKindOfClass:[NSMutableDictionary class]]) {
        
        headerStr = [self requestIsVerify];
        
        [aHeaderDict setObject:headerStr forKeyedSubscript:@"appverify"];
        
        if (self.verifyWithAppId) {
            
            [aHeaderDict setObject:self.verifyWithAppId forKey:@"x-mas-app-id"];
            
        }
        
        [aRequest setRequestHeaders:aHeaderDict];
        
    } else {
        
        headerStr = [self requestIsVerify];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:aRequest.requestHeaders];
        
        [dict setObject:headerStr forKeyedSubscript:@"appverify"];
        
        if (self.verifyWithAppId) {
            
            [dict setObject:self.verifyWithAppId forKey:@"x-mas-app-id"];
            
        }
        
        [aRequest setRequestHeaders:dict];
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
	if (perc>=100) {
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
    [euexObj uexOnUpLoadWithOpId:[self.opid intValue] fileSize:filesize percent:100 serverPath:@"" status:UEX_UPLOAD_UPLOADING];
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

#pragma mark -
#pragma mark - md5

- (NSString *)md5:(NSString *)appKeyAndAppId {
    const char *cStr = [appKeyAndAppId UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

#pragma mark -
#pragma mark - 获得当前时间戳

-(NSString *)getCurrentTS{
    unsigned long long time = [[NSDate  date] timeIntervalSince1970] * 1000;
    
    NSString * timeSp = [NSString stringWithFormat:@"%lld",time];
    return timeSp;
    //    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
    //    NSTimeInterval a = [dat timeIntervalSince1970]*1000;
    //    NSString *timeString = [NSString stringWithFormat:@"%d",a];//转为字符型
    //    return timeString;
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
