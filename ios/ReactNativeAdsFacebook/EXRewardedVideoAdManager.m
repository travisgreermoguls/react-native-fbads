#import "EXRewardedVideoAdManager.h"
#import "EXUnversioned.h"

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <React/RCTUtils.h>
#import <React/RCTLog.h>

@interface EXRewardedVideoAdManager () <FBRewardedVideoAdDelegate>

@property (nonatomic, strong) RCTPromiseResolveBlock resolveLoad;
@property (nonatomic, strong) RCTPromiseRejectBlock rejectLoad;
@property (nonatomic, strong) RCTPromiseResolveBlock resolveShow;
@property (nonatomic, strong) RCTPromiseRejectBlock rejectShow;
@property (nonatomic, strong) FBRewardedVideoAd *rewardedVideoAd;
@property (nonatomic) bool didLoad;
@property (nonatomic) bool isBackground;

@end

@implementation EXRewardedVideoAdManager

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE(CTKRewardedVideoAdManager)

- (void)setBridge:(RCTBridge *)bridge
{
  _bridge = bridge;
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(bridgeDidForeground:)
                                               name:EX_UNVERSIONED(@"EXKernelBridgeDidForegroundNotification")
                                             object:self.bridge];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(bridgeDidBackground:)
                                               name:EX_UNVERSIONED(@"EXKernelBridgeDidBackgroundNotification")
                                             object:self.bridge];
}


RCT_EXPORT_METHOD(
  loadAd:(NSString *)placementId
  resolver:(RCTPromiseResolveBlock)resolve
  rejecter:(RCTPromiseRejectBlock)reject
) 
{
  NSLog(@"Loading Rewarded Video");
  RCTAssert(_resolveLoad == nil && _rejectLoad == nil, @"Only one `loadAd` can be called at once");
  RCTAssert(_isBackground == false, @"`loadAd` can be called only when experience is running in foreground");
//  if (![EXFacebook facebookAppIdFromNSBundle]) {
//    RCTLogWarn(@"No Facebook app id is specified. Facebook ads may have undefined behavior.");
//  }
  
  _resolveLoad = resolve;
  _rejectLoad = reject;
  
  _rewardedVideoAd = [[FBRewardedVideoAd alloc] initWithPlacementID:placementId];
  _rewardedVideoAd.delegate = self;
  [self->_rewardedVideoAd loadAd];
}

RCT_EXPORT_METHOD(
  showAd:
  resolver:(RCTPromiseResolveBlock)resolve 
  rejecter:(RCTPromiseRejectBlock)reject
) 
{
  RCTAssert(_resolveShow == nil && _rejectShow == nil, @"Only one `showAd` can be called at once");
  RCTAssert(_isBackground == false, @"`showAd` can be called only when experience is running in foreground");
//  if (![EXFacebook facebookAppIdFromNSBundle]) {
//    RCTLogWarn(@"No Facebook app id is specified. Facebook ads may have undefined behavior.");
//  }
    if(_didLoad != true) {
        return reject(@"E_FAILED_TO_SHOW", @"Rewarded video ad not loaded, unable to show.", nil);
    }
    NSLog(@"Showing Ad");
    // set callback to be called by rewardedVideoAdComplete below
    _resolveShow = resolve;
    
    // dispatch async to get main UI thread to show video
    dispatch_async(dispatch_get_main_queue(), ^{
        [_rewardedVideoAd showAdFromRootViewController:RCTPresentedViewController()];
    });
}

#pragma mark - FBInterstitialAdDelegate

- (void)rewardedVideoAd:(FBRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error
{
    NSLog(@"Rewarded video ad failed to load - Error: %@", error);
    
    _didLoad = false;
    _rejectLoad(@"E_FAILED_TO_LOAD", @"Rewarded video ad failed to load", nil);
}

- (void)rewardedVideoAdDidLoad:(FBRewardedVideoAd *)rewardedVideoAd
{
    NSLog(@"Video ad is loaded and ready to be displayed");
    _didLoad = true;
    _resolveLoad(@"Video ad is loaded and ready to be displayed");
}

- (void)rewardedVideoAdDidClick:(FBRewardedVideoAd *)rewardedVideoAd
{
    NSLog(@"Video ad clicked");
}

- (void)rewardedVideoAdComplete:(FBRewardedVideoAd *)rewardedVideoAd
{
    NSLog(@"Rewarded Video ad video complete - init reward");
    
    _resolveShow(@"Rewarded video ad completed successfully.");
    
    [self cleanUpAd];
}

- (void)rewardedVideoAdDidClose:(FBRewardedVideoAd *)rewardedVideoAd
{
    NSLog(@"Rewarded Video ad closed - this can be triggered by closing the application, or closing the video end card");
}

- (void)rewardedVideoAdWillClose:(FBRewardedVideoAd *)rewardedVideoAd
{
    NSLog(@"The user clicked on the close button, the ad is just about to close");
}

- (void)rewardedVideoAdWillLogImpression:(FBRewardedVideoAd *)rewardedVideoAd
{
    NSLog(@"Rewarded Video impression is being captured");
}

- (void)bridgeDidForeground:(NSNotification *)notification
{
  _isBackground = false;
}

- (void)bridgeDidBackground:(NSNotification *)notification
{
  _isBackground = true;
}

- (void)cleanUpAd {
    _rejectLoad = nil;
    _resolveLoad = nil;
    _rejectShow = nil;
    _resolveShow = nil;
    _rewardedVideoAd = nil;
    _didLoad = false;
}

@end
