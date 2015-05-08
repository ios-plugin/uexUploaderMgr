//
//  EUExFormFile.h
//  WebKitCorePlam
//
//  Created by AppCan on 11-10-21.
//  Copyright 2011 AppCan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIProgressDelegate.h"
#import "ASIHTTPRequestDelegate.h"
#import "ASIFormDataRequest.h"

@class EUExUploaderMgr;
@interface EUExFormFile : NSObject {
	NSString *targetAddress;
	NSString *filePath;
	NSString *opid;
	BOOL isUploading;
	long long filesize;
	long long upldsize;
	NSString *receiveString;
	EUExUploaderMgr *euexObj;
	NSData *imageData;
	ASIFormDataRequest *aRequest;
}
@property(nonatomic, retain)ASIFormDataRequest *aRequest;
@property(nonatomic, retain)NSMutableDictionary *aHeaderDict;
@property(nonatomic, retain)NSData *imageData;
@property(nonatomic, assign)EUExUploaderMgr *euexObj;
@property(nonatomic, retain)NSString *targetAddress;
@property(nonatomic, retain)NSString *receiveString;
@property(nonatomic, retain)NSString *filePath;
@property(nonatomic, retain)NSString *opid;
@property(nonatomic)BOOL isUploading;
-(void)uploadingWithName:(NSString *)inName;
-(void)getJPEGFromAssetForURL:(NSURL *)url upload:(ASIFormDataRequest*)request name:(NSString *)inName;
@end
