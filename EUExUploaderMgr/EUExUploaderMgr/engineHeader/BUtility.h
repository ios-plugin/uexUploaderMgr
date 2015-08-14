//
//  BUtility.h
//  WebKitCorePlam
//
//  Created by yang fan on 11-8-23.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
//开发版本 控制
#define F_DEVELOPMENT_USE YES
//view跳转 控制
#define F_APPCANREPORT_USE     YES
//自定义事件 控制
#define ACDATAANALYSISNOUSE    YES
//更改Push动画为UIView动画  控制
#define UIVIEW_ANIMATION_PUSH_USE  NO

//[[[NSBundle mainBundle] infoDictionary] objectForKey:F_WIDGETONEVERSION]

//协议路径
#define F_HTTP_PATH			@"http://"
#define F_HTTPS_PATH		@"https://"
#define F_APP_PATH			@"wgt://"
#define F_WGTS_PATH			@"wgts://"
#define F_RES_PATH			@"res://"
#define F_BOX_PATH			@"box://"
#define F_DATA_PATH			@"data:"
#define F_WGTROOT_PATH		@"wgtroot://"


#define F_WIDGETONE_APPS_NAME		@"apps"
#define F_WIDGETONE_WIDGET_NAME		@"widget"

//BUNDLE
#define APPCANBUNDLE_NAME @"appCan.bundle"
#define APPCANBUNDLE_PATH [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: APPCANBUNDLE_NAME] 
#define APPCANBUNDLE [NSBundle bundleWithPath: APPCANBUNDLE_PATH]
//encriypt
 
#define JSENCRYPTKEY			@"ZYWXWIDGETENCRYPTFORWEBKIT20111101"

#define MAMENCRYPTKEY			@"ZYWXWIDGETENCRYPTFORWEBKIT20121211225XLL"
//ud key
#define F_UD_BadgeNumber        @"AppCanBadgeNumber"

#define F_UD_StandardWgt          @"standWgt"
#define F_UD_UpdateWgtID        @"AppCanWgtID"

//clientCertificate.p12
//#define ClientCertficate_PATH [NSString stringWithFormat:@"%@/Documents/widget/wgtRes/clientCertificate.p12", NSHomeDirectory()]

#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)

//引擎内部Log
#ifndef OUTPUT_LOG
#define OUTPUT_LOG
#endif

#ifdef OUTPUT_LOG
#ifndef ZD_OUTPUT_LOG_LIFE
#define ZD_OUTPUT_LOG_LIFE
#endif
#ifndef ZD_OUTPUT_LOG_ACTION
#define ZD_OUTPUT_LOG_ACTION
#endif
#ifndef ZD_OUTPUT_LOG_CONSOLE
#define ZD_OUTPUT_LOG_CONSOLE
#endif
#ifndef ZD_OUTPUT_LOG_FILE
#define ZD_OUTPUT_LOG_FILE
#endif
#ifndef YF_OUTPUT_LOG_CONSOLE
#define YF_OUTPUT_LOG_CONSOLE
#endif
#ifndef YF_OUTPUT_LOG_FILE
#define YF_OUTPUT_LOG_FILE
#endif
#ifndef LL_OUTPUT_LOG_CONSOLE
#define LL_OUTPUT_LOG_CONSOLE
#endif
#ifndef LL_OUTPUT_LOG_FILE
#define LL_OUTPUT_LOG_FILE
#endif
#ifndef ZDC_OUTPUT_LOG_CONSOLE
#define ZDC_OUTPUT_LOG_CONSOLE
#endif
#ifndef ZDCC_OUTPUT_LOG_CONSOLE
#define ZDCC_OUTPUT_LOG_CONSOLE
#endif
#ifndef ZDMG_OUTPUT_LOG_CONSOLE
#define ZDMG_OUTPUT_LOG_CONSOLE
#endif
#ifndef ZDC_OUTPUT_LOG_FILE
#define ZDC_OUTPUT_LOG_FILE
#endif
#ifndef ZDTHREAD_OUTPUT_LOG_CONSOLE
#define ZDTHREAD_OUTPUT_LOG_CONSOLE
#endif
#ifndef ZDFLOW_OUTPUT_LOG_CONSOLE
#define ZDFLOW_OUTPUT_LOG_CONSOLE
#endif
#ifndef CHB_OUTPUT_LOG_CONSOLE
#define CHB_OUTPUT_LOG_CONSOLE
#endif
//插件log
#ifndef Plugin_OUTPUT_LOG_CONSOLE
#define Plugin_OUTPUT_LOG_CONSOLE
#endif

#endif



#define rgba(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
//rc4
struct rc4_state 
{ 
    int x, y, m[256]; 
};
void rc4_setup( struct rc4_state *s, unsigned char *key, int length); 
void rc4_crypt( struct rc4_state *s, unsigned char *data, int length);
//Log 
void ZDACNSLog (NSString *format,...);
void ZDNSLog (NSString *format, ...);
void ZDCNSLog (NSString *format, ...);
void ZDCCNSLog (NSString *format, ...);
void ZDMGNSLog (NSString *format, ...);
void ZDThreadNSLog (NSString *format, ...);
void ZDFlowNSLog (NSString *format, ...);
void ZDLIFENSLog (NSString *format, ...);
void YFNSLog (NSString *format, ...);
void LLNSLog (NSString *format, ...);
void PluginNSLog (NSString *format, ...);
void HBNSLog(NSString *format, ...);

void ZDNSLogWithString(NSString *inFormat, NSString *inValue);
void ZDNSLogWithInt(NSString *inFormat, int inValue);
void ZDNSLogWithFloat(NSString *inFormat, float inValue);

void YFNSLogWithString(NSString *inFormat, NSString *inValue);
void YFNSLogWithInt(NSString *inFormat, int inValue);
void YFNSLogWithFloat(NSString *inFormat, float inValue);

void LLNSLogWithString(NSString *inFormat, NSString *inValue);
void LLNSLogWithInt(NSString *inFormat, int inValue);
void LLNSLogWithFloat(NSString *inFormat, float inValue);
NSString *getAppCanBundlePath(NSString *filename);

typedef union _BGColor {
	struct _rgba { 
		unsigned char r,g,b,a;
	} rgba;
	unsigned int hex; 
} BGColor;
@class EUExAction;
@class EBrowserView;
@interface BUtility : NSObject {

}
//base js
+(NSString*)getBaseJSKey;
//rc4 js
+(NSString*)getRC4LocalStoreJSKey;
//doc path
+(void)setAppCanDocument;
//dev
+(void)setAppCanDevMode:(NSString*)inValue;
+(BOOL)getAppCanDevMode;
//client https pwd
+(void)setClientCertificatePwd:(NSString*)inPwd;
+(NSString*)ClientCertificatePassWord;

+ (NSString *) platform;
+(NSString *)getDeviceIdentifyNo;
//+(BOOL)isPhoneNumber:(NSString*)inPhoneNum;
+(int)getScreenWidth;
+(int)getScreenHeight;
+(NSString*)getScreenWAndH;
+(float)getSystemVersion;
+(BOOL) isIpad;
+(BOOL)isSimulator;
+(NSString*)getDeviceVer;
+(NSString*)makeSpecUrl:(NSString*)inStr;
+(NSString*)makeUrl:(NSString*)inBaseUrl url:(NSString*)inUrl;
+(NSString *)getDocumentsPath:(NSString *)fileName;
+(NSString *)getResPath:(NSString *)fileName;
+(int)lastIndexOf:(NSString*)baseString findChar:(char)inChar;
//+(NSMutableArray*)convertToArray:(NSURL*)inURL;
+(EUExAction *)convertToAction:(NSURL*)inURL;
+(NSURL*)stringToUrl:(NSString *)inString;
+(NSString*)wgtResPath:(NSString*)inUrl;
+ (UIColor *) colorWithHexString: (NSString *) stringToConvert;
+(BOOL) isValidateOrientation:(UIInterfaceOrientation)inOrientation;
+ (BGColor)bgColorFromNSString:(NSString*)inColorStr;
/*
 *判断是否有某个字符
 */
+(BOOL)isHaveString:(NSString *)inSouceString subSting:(NSString *)inSubString;
+(int)fileisDirectoy:(NSString *)fileName;
+(NSString *)AESDecryptFile:(NSString *)srcFile;
+(void)writeLog:(NSString*)inLog;
+ (void)cookieDebugForBroad;
+(NSString *)getTransferredString:(NSData *)inData;
+(UIImage*)imageByScalingAndCroppingForSize:(UIImage *)sourceImage;
+(BOOL) isConnected;
+(double)usedMemory;
+(double)availableMemory;
+(void)exitWithClearData;
+(UIImage *)rotateImage:(UIImage *)aImage;
//数据统计
+(NSString*)appKey;
+(NSString*)appId;
+(void)setAppCanViewBackground:(int)wgtType name:(NSString*)inName closeReason:(int)inOpenReason;
+(void)setAppCanViewActive:(int)wgtType opener:(NSString*)inOpener name:(NSString*)inName openReason:(int)inOpenReason mainWin:(int)inMainWnd;
//mac
+(NSString *)macAddress;
//absPath
+(NSString*)getAbsPath:(EBrowserView*)meBrwView path:(NSString*)inPath;

+ (int)getRand ;
+(NSString*)rc4WithInput:(NSString*)aInput key:(NSString*)aKey;
+(NSString*)RC4DecryptWithInput:(NSString*)aInput key:(NSString*)aKey;
//p12 https://
+(BOOL)extractIdentity:(NSString*)pwdStr andIdentity:(SecIdentityRef *)outIdentity andTrust:(SecTrustRef*)outTrust andCertChain:(SecCertificateRef*)outCertChain fromPKCS12Data:(NSData *)inPKCS12Data;
+(NSString*)clientCertficatePath;
//icloud
+(float)getSDKVersion;
+(BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL;
+(NSString *)getCachePath:(NSString *)fileName;
#pragma mark - Jailbroken
+(BOOL)isJailbroken;

+(void)evaluatingJavaScriptInRootWnd:(NSString*)script_;
+(void)evaluatingJavaScriptInFrontWnd:(NSString*)script_;
//szc 获取config屏幕方向信息
+(NSString * )getMainWidgetConfigInterface;
@end
