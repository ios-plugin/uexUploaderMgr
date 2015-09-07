//
//  untitled.h
//  WBPalm
//
//  Created by 邹 达 on 11-9-3.
//  Copyright 2011 zywx. All rights reserved.
//



@class EBrowserController;
@class EBrowser;
@class WWidgetMgr;
@class PluginParser;
@interface WidgetOneDelegate: NSObject <UIApplicationDelegate,UIAlertViewDelegate> {
	UIWindow *mWindow;
	EBrowserController *meBrwCtrler;
	WWidgetMgr *mwWgtMgr;
	PluginParser *pluginObj;
}
@property (nonatomic, retain) UIWindow *mWindow;
@property (nonatomic, assign) EBrowserController *meBrwCtrler;
@property (nonatomic, assign) WWidgetMgr *mwWgtMgr;
@property (nonatomic) BOOL userStartReport;
@property (nonatomic) BOOL useOpenControl;
@property (nonatomic) BOOL useUpdateControl;
@property (nonatomic) BOOL useOnlineArgsControl;
@property (nonatomic) BOOL usePushControl;
@property (nonatomic) BOOL useDataStatisticsControl;
@property (nonatomic) BOOL useAuthorsizeIDControl;
@property (nonatomic) BOOL useCloseAppWithJaibroken;
@property (nonatomic) BOOL useRC4EncryptWithLocalstorage;
@property (nonatomic) BOOL useUpdateWgtHtmlControl;
@property (nonatomic) BOOL useCertificateControl;
@property (nonatomic) BOOL useIsHiddenStatusBarControl;
@property (nonatomic,readonly) BOOL useEraseAppDataControl;
@property(nonatomic,copy)NSString *useStartReportURL;
@property(nonatomic,copy)NSString *useAnalysisDataURL;
@property(nonatomic,copy)NSString *useBindUserPushURL;
@property(nonatomic,copy)NSString *useAppCanMAMURL;
@property(nonatomic,copy)NSString *useCertificatePassWord;


//-(NSString *)getPayPublicRsaKey;

@end

#define theApp ((WidgetOneDelegate *)[[UIApplication sharedApplication] delegate])