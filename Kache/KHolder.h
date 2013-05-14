//
//  KHolder.h
//  KacheDemo
//
//  Created by jiajun on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KObject;

@interface KHolder : NSObject
{
    NSMutableDictionary         *objects;
    NSMutableArray              *keys;
    NSUInteger                  size;
}

- (id)initWithToken:(NSString *)token;

- (void)setValue:(id)value forKey:(NSString *)key expiredAfter:(NSInteger)duration;
- (id)valueForKey:(NSString *)key;
- (KObject *)objectForKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;

- (NSDictionary *)serialize;
- (void)unserializeFrom:(NSDictionary *)dict;

@end
