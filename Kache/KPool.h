//
//  KPool.h
//  KacheDemo
//
//  Created by jiajun on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KHolder;

@interface KPool : NSObject

@property (assign, nonatomic)   NSString          *name;
@property (assign, nonatomic)   NSInteger         size;

- (KPool *)initWithHolder:(KHolder *)holder;
- (void)setValue:(id)value forKey:(NSString *)key expiredAfter:(NSInteger)duration;
- (void)removeObjectForKey:(NSString *)key;

- (NSDictionary *)serialize;
- (void)unserializeFrom:(NSDictionary *)dict;

@end
