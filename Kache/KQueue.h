//
//  KQueue.h
//  KacheDemo
//
//  Created by jiajun on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KHolder;

@interface KQueue : NSObject

@property (assign, nonatomic)   NSString          *name;
@property (assign, nonatomic)   NSInteger         size;

- (KQueue *)initWithHolder:(KHolder *)holder;

- (void)push:(id)data;
- (id)pop;

- (NSDictionary *)serialize;
- (void)unserializeFrom:(NSDictionary *)dict;

@end
