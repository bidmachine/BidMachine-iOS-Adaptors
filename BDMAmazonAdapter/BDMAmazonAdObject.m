//
//  BDMAmazonAdObject.m
//  BDMAmazonAdapter
//
//  Created by Ilia Lozhkin on 07.09.2020.
//  Copyright © 2020 Stas Kochkin. All rights reserved.
//

#import "BDMAmazonAdObject.h"

@implementation BDMAmazonBannerAdapter

- (UIView *)adView {
    return UIView.new;
}

- (void)prepareContent:(BDMStringToObjectMap *)contentInfo {}

- (void)presentInContainer:(UIView *)container {}


@end

@implementation BDMAmazonInterstitialAdapter

- (UIView *)adView {
    return UIView.new;
}

- (void)prepareContent:(BDMStringToObjectMap *)contentInfo { }

- (void)present { }

@end
