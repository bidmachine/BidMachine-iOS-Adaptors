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


@interface BDMVASTVideoAdapter () <STKVASTControllerDelegate, STKProductControllerDelegate>

@property (nonatomic, strong) STKVASTController *videoController;
@property (nonatomic, strong) STKProductController *productPresenter;
@property (nonatomic,   copy) NSDictionary<NSString *,NSString *> * contentInfo;

@end

@implementation BDMVASTVideoAdapter

- (UIView *)adView {
    return self.videoController.view;
}

- (void)prepareContent:(NSDictionary<NSString *,NSString *> *)contentInfo {
    NSString *rawXML        = ANY(contentInfo).from(BDMVASTCreativeKey).string;
    NSData *xmlData         = [rawXML dataUsingEncoding:NSUTF8StringEncoding];
    self.contentInfo        = contentInfo;
    
    self.videoController    = [[STKVASTController alloc] initWithConfiguration: [STKVASTControllerConfiguration configuration:^(STKVASTControllerConfigurationBuilder *builder) {
        builder.appendRewarded(self.rewarded);
        builder.appendAutoclose(NO);
        builder.appendForceCloseTime(ANY(contentInfo).from(BDMVASTUseNativeCloseKey).number.boolValue);
        builder.appendCloseTime(ANY(contentInfo).from(BDMVASTCompanionSkipOffsetKey).number.doubleValue);
        builder.appendMaxDuration(ANY(contentInfo).from(BDMVASTMaxDurationKey).number.doubleValue ?: 180);
        builder.appendVideoCloseTime(ANY(contentInfo).from(BDMVASTVideoSkipOffsetKey).number.doubleValue);
    }]];
    
    [self.videoController setDelegate:self];
    [self.videoController loadForVastXML:xmlData];
}

- (void)present {
    [self.videoController presentFromViewController:self.rootViewController];
}

#pragma mark - Private

- (STKProductController *)productPresenter {
    if (!_productPresenter) {
        _productPresenter = [STKProductController new];
        _productPresenter.delegate = self;
    }
    return _productPresenter;
}

- (NSDictionary *(^)(NSString *))productParameters {
    return ^NSDictionary *(NSString *url){
        NSMutableDictionary *productParameters = self.contentInfo.mutableCopy;
        productParameters[STKProductParameterClickThrough] = url;
        return productParameters.copy;
    };
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

- (void)vastControllerDidClick:(STKVASTController *)controller clickURL:(NSString *)clickURL {
    [STKSpinnerScreen show];
    [self.productPresenter presentProductWithParameters:self.productParameters(clickURL)];
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

#pragma mark - STKVASTControllerDelegate parameters

- (UIViewController *)rootViewController {
    return [self.displayDelegate rootViewControllerForAdapter:self] ?: UIViewController.stk_topPresentedViewController;
}

#pragma mark - STKProductControllerDelegate

- (void)controller:(STKProductController *)controller didFailToPresentWithError:(NSError *)error {
    [STKSpinnerScreen hide];
}

- (void)controller:(STKProductController *)controller willLeaveApplicationToProductWithParameters:(NSDictionary <NSString *, id> *)parameters {
    [self.displayDelegate adapterRegisterUserInteraction:self];
    [STKSpinnerScreen hide];
}

- (void)controller:(STKProductController *)controller willPresentProductWithParameters:(NSDictionary <NSString *, id> *)parameters {
    [self.displayDelegate adapterRegisterUserInteraction:self];
    [self.videoController pause];
    [STKSpinnerScreen hide];
}

- (void)controller:(STKProductController *)controller didDismissProductWithParameters:(NSDictionary <NSString *, id> *)parameters {
     [self.videoController resume];
}

@end
