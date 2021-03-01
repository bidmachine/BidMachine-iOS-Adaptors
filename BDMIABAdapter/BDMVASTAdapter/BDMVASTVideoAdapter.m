//
//  BDMVASTVideoAdapter.m
//  BDMVASTVideoAdapter
//
//  Created by Pavel Dunyashev on 24/09/2018.
//  Copyright © 2018 Appodeal. All rights reserved.
//

@import StackUIKit;
@import StackVASTKit;
@import StackFoundation;
@import BidMachine.Adapters;

#import "BDMVASTNetwork.h"
#import "BDMVASTVideoAdapter.h"


@interface BDMVASTVideoAdapter () <STKVASTControllerDelegate>

@property (nonatomic, strong) STKVASTController *videoController;
@property (nonatomic,   copy) BDMStringToObjectMap *contentInfo;

@end

@implementation BDMVASTVideoAdapter

- (UIView *)adView {
    return self.videoController.view;
}

- (void)prepareContent:(BDMStringToObjectMap *)contentInfo {
    NSString *rawXML        = ANY(contentInfo).from(kBDMCreativeAdm).string;
    NSData *xmlData         = [rawXML dataUsingEncoding:NSUTF8StringEncoding];
    self.contentInfo        = contentInfo;
    
    self.videoController    = [[STKVASTController alloc] initWithConfiguration: [STKVASTControllerConfiguration configuration:^(STKVASTControllerConfigurationBuilder *builder) {
        builder.appendRewarded(self.rewarded);
        builder.appendAutoclose(NO);
        builder.appendForceCloseTime(ANY(contentInfo).from(kBDMCreativeUseNativeClose).number.boolValue);
        builder.appendMaxDuration(180);
        builder.appendVideoCloseTime(ANY(contentInfo).from(kBDMCreativeCloseTime).number.doubleValue);
        builder.appendProductParameters(ANY(contentInfo).from(kBDMCreativeStoreParams).value);
        builder.appendPartnerName(kBDMOMPartnerName);
        builder.appendPartnerVersion(kBDMVersion);
        builder.appendMeasuring(YES);
    }]];
    
    [self.videoController setDelegate:self];
    [self.videoController loadForVastXML:xmlData];
}

- (void)present {
    [self.videoController presentFromViewController:self.rootViewController];
}

#pragma mark - STKVASTControllerDelegate

- (void)vastControllerReady:(STKVASTController *)controller {
    [self.loadingDelegate adapterPreparedContent:self];
}

- (void)vastController:(STKVASTController *)controller didFailToLoad:(NSError *)error {
    [self.loadingDelegate adapter:self failedToPrepareContentWithError: [error bdm_wrappedWithCode:BDMErrorCodeNoContent]];
}

- (void)vastController:(STKVASTController *)controller didFailWhileShow:(NSError *)error {
    [self.displayDelegate adapter:self failedToPresentAdWithError: [error bdm_wrappedWithCode:BDMErrorCodeBadContent]];
}

- (void)vastControllerDidDismiss:(STKVASTController *)controller {
    [self.displayDelegate adapterDidDismiss:self];
}

- (void)vastControllerDidFinish:(STKVASTController *)controller {
    [self.displayDelegate adapterFinishRewardAction:self];
}

- (void)vastControllerDidPresent:(STKVASTController *)controller {
    [self.displayDelegate adapterWillPresent:self];
}

- (void)vastControllerDidSkip:(STKVASTController *)controller {
    // NO-OP
}

- (BOOL)vastController:(nonnull STKVASTController *)controller shouldProcessNavigationWithURL:(nonnull NSURL *)URL {
    return YES;
}

- (void)vastControllerWillLeaveApplication:(nonnull STKVASTController *)controller {
    [self.displayDelegate adapterRegisterUserInteraction:self];
}

- (void)vastControllerWillPresentProductScreen:(nonnull STKVASTController *)controller {
    [self.displayDelegate adapterRegisterUserInteraction:self];
}

- (void)vastControllerDidDismissProductScreen:(nonnull STKVASTController *)controller {
    // NO-OP
}

- (UIViewController *)rootViewController {
    return [self.displayDelegate rootViewControllerForAdapter:self] ?: UIViewController.stk_topPresentedViewController;
}

@end
