//
//  BDMMRAIDConfiguration.h
//  BDMMRAIDAdapter
//
//  Created by Ilia Lozhkin on 05.01.2021.
//  Copyright © 2021 Stas Kochkin. All rights reserved.
//

@import BidMachine.Adapters;

#import <StackMRAIDKit/StackMRAIDKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDMMRAIDConfiguration : STKMRAIDPresentationConfiguration

+ (instancetype)configuraton:(BDMStringToObjectMap *)info;

@end

NS_ASSUME_NONNULL_END
