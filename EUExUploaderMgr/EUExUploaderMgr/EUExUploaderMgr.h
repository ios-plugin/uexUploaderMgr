//
//  EUExUploaderMgr.h
//  AppCan
//
//  Created by AppCan on 11-10-18.
//  Copyright 2011 AppCan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EUExBase.h"
#import "EUExFormFile.h"

 
#define UEX_UPLOAD_UPLOADING  0
#define UEX_UPLOAD_FINISH	  1
#define UEX_UPLOAD_FAIL       2

@interface EUExUploaderMgr : EUExBase <ASIProgressDelegate,ASIHTTPRequestDelegate>{
	NSMutableDictionary *formDict;
	
}
@property(nonatomic,retain)	NSMutableDictionary *formDict;
-(void)uexOnUpLoadWithOpId:(int)inOpId fileSize:(int)inFileSize percent:(int)inPercent serverPath:(NSString *)inServerPath status:(int)inStatus;
@end
