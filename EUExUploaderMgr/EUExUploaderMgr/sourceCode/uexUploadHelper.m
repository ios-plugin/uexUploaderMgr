/**
 *
 *	@file   	: uexUploadHelper.m  in EUExUploaderMgr
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

#import "uexUploadHelper.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <CommonCrypto/CommonCrypto.h>



@implementation uexUploadHelper



+ (NSString *)MIMETypeForPathExtension:(NSString *)ext{
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)ext, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        return @"application/octet-stream";
    } else {
        return contentType;
    }
    
}

+ (NSDictionary<NSString *,NSString *> *)AppCanHTTPHeadersWithEUExObj:(nullable __kindof EUExBase *)euexObj;
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    id<AppCanWidgetObject> widget = euexObj.webViewEngine.widget;
    if (!widget) {
        widget = AppCanMainWidget();
    }
    NSString *time= [self timestampStringFromDate:[NSDate date]];
    NSString *appId = @"";
    NSString *appKey = @"";
    
    NSString *pluginStr = @"widget/plugin";
    if ([widget.indexUrl rangeOfString:pluginStr].length == [pluginStr length]) {
        id<AppCanWidgetObject> mainWgt = AppCanMainWidget();
        appId = mainWgt.appId;
        appKey = mainWgt.widgetOneId;
        
        
    } else {
        if (widget.appKey) {
            appKey = [NSString stringWithFormat:@"%@",widget.appKey];
        }else{
            appKey = [NSString stringWithFormat:@"%@",widget.widgetOneId];
        }
        appId = widget.appId;
    }
    
    NSString *verifyStr = [self MD5:[NSString stringWithFormat:@"%@:%@:%@",appId,appKey,time]];
    verifyStr = [NSString stringWithFormat:@"md5=%@;ts=%@;",verifyStr,time];
    [dict setValue:appId forKey:@"x-mas-app-id"];
    [dict setValue:verifyStr forKey:@"appverify"];
    return [dict copy];
}

+ (NSString *)MD5:(NSString *)str{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, strlen(cStr), result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}
+ (NSString *)timestampStringFromDate:(NSDate *)date{
    unsigned long long time = [date timeIntervalSince1970] * 1000;
    NSString * timestamp = [NSString stringWithFormat:@"%lld",time];
    return timestamp;
}

@end




