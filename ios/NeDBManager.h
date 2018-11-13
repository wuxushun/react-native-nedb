//
//  NeDBManager.h
//  nedb
//
//  Created by wuxushun on 2018/11/12.
//  Copyright © 2018 Facebook. All rights reserved.
//

#if __has_include(<React/RCTBridgeModule.h>)
#import <React/RCTBridgeModule.h>
#else
#import "RCTDevMenu.h"
#endif
#if __has_include(<React/RCTLog.h>)
#import <React/RCTLog.h>
#else
#import "RCTDevMenu.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface NeDBManager : NSObject<RCTBridgeModule>

@end

NS_ASSUME_NONNULL_END
