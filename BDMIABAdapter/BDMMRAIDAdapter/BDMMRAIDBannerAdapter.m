//
//  BDMMRAIDBannerAdapter.m
//  BDMMRAIDBannerAdapter
//
//  Created by Pavel Dunyashev on 11/09/2018.
//  Copyright © 2018 Appodeal. All rights reserved.
//

@import StackUIKit;
@import StackMRAIDKit;
@import StackFoundation;

#import "BDMMRAIDConfiguration.h"
#import "BDMMRAIDBannerAdapter.h"


const CGSize kBDMAdSize320x50  = {.width = 320.0f, .height = 50.0f  };
const CGSize kBDMAdSize728x90  = {.width = 728.0f, .height = 90.0f  };

@interface BDMMRAIDBannerAdapter () <STKMRAIDAdDelegate, STKMRAIDServiceDelegate, STKMRAIDViewPresenterDelegate>

@property (nonatomic, strong) STKMRAIDAd *ad;
@property (nonatomic, strong) STKMRAIDViewPresenter *presenter;

@property (nonatomic,   weak) UIView *container;

@end

@implementation BDMMRAIDBannerAdapter

- (UIView *)adView {
    return self.presenter;
}

- (void)prepareContent:(BDMStringToObjectMap *)contentInfo {
    CGSize bannerSize               = [self sizeFromContentInfo:contentInfo];
    CGRect frame                    = (CGRect){.size = bannerSize};
    NSArray *mraidFeatures          = @[kMRAIDSupportsInlineVideo, kMRAIDSupportsLogging, kMRAIDMeasure];
    
    self.adContent                  = ANY(contentInfo).from(kBDMCreativeAdm).string;
    self.ad                         = [STKMRAIDAd new];
    self.ad.delegate                = self;
    self.ad.service.delegate        = self;
    self.presenter                  = [[STKMRAIDViewPresenter alloc] initWithConfiguration:[BDMMRAIDConfiguration configuraton:contentInfo]];
    self.presenter.delegate         = self;
    self.presenter.frame            = frame;
    
    [self.ad.service.configuration registerServices:mraidFeatures];
    self.ad.service.configuration.partnerName = kBDMOMPartnerName;
    self.ad.service.configuration.partnerVersion = kBDMVersion;
    [self.ad loadHTML:self.adContent];
}

- (void)presentInContainer:(UIView *)container {
    [container.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [container addSubview:self.presenter];
    [self.presenter presentAd:self.ad];
    self.container = container;
}

#pragma mark - Private

- (CGSize)sizeFromContentInfo:(NSDictionary *)contentInfo {
    NSNumber *width     = ANY(contentInfo).from(kBDMCreativeWidth).number;
    NSNumber *height    = ANY(contentInfo).from(kBDMCreativeHeight).number;
    
    if (ANY(width).number <= 0 || ANY(height).number <= 0) {
        return [self defaultAdSize];
    }
    
    return CGSizeMake(width.floatValue, height.floatValue);
}

- (CGSize)defaultAdSize {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? kBDMAdSize728x90 : kBDMAdSize320x50;
}

#pragma mark - STKMRAIDAdDelegate

- (void)didLoadAd:(STKMRAIDAd *)ad {
    [self.loadingDelegate adapterPreparedContent:self];
}

- (void)didFailToLoadAd:(STKMRAIDAd *)ad withError:(NSError *)error {
    [self.loadingDelegate adapter:self failedToPrepareContentWithError:error];
}

- (BOOL)ad:(STKMRAIDAd *)ad shouldProcessNavigationWithURL:(NSURL *)URL {
    return YES;
}

#pragma mark - STKMRAIDServiceDelegate

- (void)mraidServiceDidReceiveLogMessage:(NSString *)message {
    BDMLog(@"%@", message);
}

#pragma mark - STKMRAIDViewPresenterDelegate

- (void)presenterWillLeaveApplication:(id<STKMRAIDPresenter>)presenter {
    [self.displayDelegate adapterRegisterUserInteraction:self];
    [self.displayDelegate adapterWillLeaveApplication:self];
}

- (void)presenterWillPresentProductScreen:(id<STKMRAIDPresenter>)presenter {
    [self.displayDelegate adapterRegisterUserInteraction:self];
    [self.displayDelegate adapterWillPresentScreen:self];
}

- (void)presenterDidDismissProductScreen:(id<STKMRAIDPresenter>)presenter {
    [self.displayDelegate adapterDidDismissScreen:self];
}

- (UIViewController *)presenterRootViewController {
    return [self.displayDelegate rootViewControllerForAdapter:self] ?: UIViewController.stk_topPresentedViewController;
}

@end
