//
//  BDMNASTNetwork.m
//  BDMNASTAdapter
//
//  Created by Stas Kochkin on 04/11/2018.
//  Copyright © 2018 Stas Kochkin. All rights reserved.
//

#import "BDMNASTNetwork.h"
#import "BDMNASTNativeAdServiceAdapter.h"

#import <StackNASTKit/StackNASTKit.h>


@implementation BDMNASTNetwork

- (NSString *)name {
    return @"nast";
}

- (NSString *)sdkVersion {
    return StackNASTKitVersion;
}

- (id<BDMNativeAdServiceAdapter>)nativeAdAdapterForSdk:(BDMSdk *)sdk {
    return [BDMNASTNativeAdServiceAdapter new];
}

@end
