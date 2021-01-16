//
//  BDMMRAIDConfiguration.m
//  BDMMRAIDAdapter
//
//  Created by Ilia Lozhkin on 05.01.2021.
//  Copyright © 2021 Stas Kochkin. All rights reserved.
//

#import "BDMMRAIDConfiguration.h"

#import <StackFoundation/StackFoundation.h>

@implementation BDMMRAIDConfiguration

+ (instancetype)configuraton:(BDMStringToObjectMap *)info {
    BDMMRAIDConfiguration *configuration    = BDMMRAIDConfiguration.new;
    configuration.closeTime                 = ANY(info).from(kBDMCreativeCloseTime).number.doubleValue;
    configuration.duration                  = ANY(info).from(kBDMCreativeDuration).number.doubleValue;
    configuration.useNativeClose            = ANY(info).from(kBDMCreativeUseNativeClose).number.boolValue;
    configuration.r1                        = ANY(info).from(kBDMCreativeCustomR1).number.boolValue;
    configuration.r2                        = ANY(info).from(kBDMCreativeCustomR2).number.boolValue;
    configuration.ignoresSafeAreaLayout     = ANY(info).from(kBDMCreativeIgnoresSafeAreaLayout).number.boolValue;
    configuration.productLink               = ANY(info).from(kBDMCreativeProductLink).string;
    configuration.productParameters         = ANY(info).from(kBDMCreativeStoreParams).value;
    configuration.countdownAsset            = [self assetFromInfo:ANY(info).from(kBDMControlCountdown).value];
    configuration.closableAsset             = [self assetFromInfo:ANY(info).from(kBDMControlCloseButton).value];
    configuration.progressAsset             = [self assetFromInfo:ANY(info).from(kBDMControlProgress).value];
    
    // backgroundColor
    
    return configuration;
}

+ (STKIABAsset *)assetFromInfo:(BDMStringToObjectMap *)info {
    STKIABAsset *asset      = STKIABAsset.new;
    asset.style             = ANY(info).from(kBDMAssetStyle).string;
    asset.visible           = ANY(info).from(kBDMAssetVisible).number.boolValue;
    asset.strokeColor       = UIColor.stk_fromHex(ANY(info).from(kBDMAssetStrokeColor).string);
    asset.fillColor         = UIColor.stk_fromHex(ANY(info).from(kBDMAssetFillColor).string);
    asset.shadowColor       = UIColor.stk_fromHex(ANY(info).from(kBDMAssetShadowColor).string);
    asset.hideAfter         = ANY(info).from(kBDMAssetHideAfter).number.doubleValue;
    asset.opacity           = ANY(info).from(kBDMAssetOpacity).number.floatValue;
    asset.outlined          = ANY(info).from(kBDMAssetOutlined).number.boolValue;
    asset.strokeWidth       = ANY(info).from(kBDMAssetStrokeWidth).number.floatValue;
    asset.content           = ANY(info).from(kBDMAssetContent).string;
    asset.size              = ({
        CGFloat width           = ANY(info).from(kBDMAssetWidth).number.floatValue;
        CGFloat height          = ANY(info).from(kBDMAssetHeight).number.floatValue;
        CGSizeMake(width, height);
    });
    asset.horizontalPostion = ({
        NSString *x = ANY(info).from(kBDMAssetPositionX).string;
        STKIABAssetHorizontalPositionFromSTKIABString(x, STKIABAssetHorizontalPositionLeft);
    });
    asset.verticalPostion   = ({
        NSString *y = ANY(info).from(kBDMAssetPositionY).string;
        STKIABAssetVerticalPositionFromSTKIABString(y, STKIABAssetVerticalPositionTop);
    });
    asset.insets            = ({
        NSString *padding = ANY(info).from(kBDMAssetPadding).string;
        UIEdgeInsetsFromSTKIABString(padding, STKIABDefaultInsets());
    });
    asset.margin            = ({
        NSString *margin = ANY(info).from(kBDMAssetMargin).string;
        UIEdgeInsetsFromSTKIABString(margin, STKIABDefaultInsets());
    });
    asset.font              = ({
        NSString *font = ANY(info).from(kBDMAssetFont).string;
        UIFontFromSTKIABFontStyleString(font);
    });
    
    return asset;
}

@end
