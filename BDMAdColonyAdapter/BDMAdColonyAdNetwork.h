//
//  BDMAdColonyAdapter.h
//  BDMAdColonyAdapter
//
//  Created by Stas Kochkin on 19/07/2019.
//  Copyright © 2019 Stas Kochkin. All rights reserved.
//

@import AdColony;
@import Foundation;
@import BidMachine;
@import BidMachine.Adapters;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const BDMAdColonyZoneIDKey;
FOUNDATION_EXPORT NSString *const BDMAdColonyAdmKey;

@interface BDMAdColonyAdNetwork : NSObject <BDMNetwork>

@end

NS_ASSUME_NONNULL_END
