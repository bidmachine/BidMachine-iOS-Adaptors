//
//  BDMAppRollAdNetwork.m
//  BDMAppRollAdapter
//
//  Created by Ilia Lozhkin on 16.11.2020.
//  Copyright © 2020 Stas Kochkin. All rights reserved.
//

@import StackFoundation;
@import AppRollSDK;

#import "BDMAppRollAdNetwork.h"

NSString *const BDMAppRollIDKey                      = @"approll_id";

@interface BDMAppRollAdNetwork()

@property (nonatomic, assign) BOOL initialized;

@end

@implementation BDMAppRollAdNetwork

- (NSString *)name {
    return @"approll";
}

- (NSString *)sdkVersion {
    return @"3.1.2";
}

- (void)initialiseWithParameters:(NSDictionary<NSString *,id> *)parameters
                      completion:(void (^)(BOOL, NSError * _Nullable))completion {
    if (self.initialized) {
        STK_RUN_BLOCK(completion, NO, nil);
        return;
    }
    
    NSString *appRollID = ANY(parameters).from(BDMAppRollIDKey).string;
    if (!NSString.stk_isValid(appRollID)) {
        NSError *error = [NSError bdm_errorWithCode:BDMErrorCodeHeaderBiddingNetwork
                                        description:@"AppRoll adapter was not receive valid partner id"];
        STK_RUN_BLOCK(completion, NO, error);
        return;
    }
    self.initialized = YES;
    [[AppRollSDK sharedInstance] initSession:appRollID];
    STK_RUN_BLOCK(completion, YES, nil);
}

@end
