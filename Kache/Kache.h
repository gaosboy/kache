//
//  Kache.h
//  KacheDemo
//
//  Created by jiajun on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KHolder;

@interface Kache : NSObject

@property (strong, nonatomic)   NSString            *filetoken;

- (id)initWithFiletoken:(NSString *)filetoken;

- (void)newQueueWithName:(NSString *)name size:(NSInteger)size;
- (void)newPoolWithName:(NSString *)name size:(NSInteger)size;

- (void)setValue:(id)value forKey:(NSString *)key expiredAfter:(NSInteger)duration;
- (void)setValue:(id)value inPool:(NSString *)name forKey:(NSString *)key expiredAfter:(NSInteger)duration;
- (void)pushValue:(id)value toQueue:(NSString *)name;
- (void)removeObjectForKey:(NSString *)key;


- (id)popFromQueue:(NSString *)name;
- (id)valueForKey:(NSString *)key;

- (void)save;
- (void)load;

+ (Kache *)instance;
+ (void)setValue:(id)value forKey:(NSString *)key expiredAfter:(NSInteger)duration;
+ (void)setValue:(id)value inDefaultPoolForKey:(NSString *)key expiredAfter:(NSInteger)duration;
+ (void)removeObjectForKey:(NSString *)key;
+ (void)pushValue:(id)value;
+ (id)popValue;
+ (id)valueForKey:(NSString *)key;

+ (void)setValue:(id)value inPool:(NSString *)name forKey:(NSString *)key expiredAfter:(NSInteger)duration;
+ (void)pushValue:(id)value toQueue:(NSString *)name;
+ (id)popFromQueue:(NSString *)name;

+ (void)newQueueWithName:(NSString *)name size:(NSInteger)size;
+ (void)newPoolWithName:(NSString *)name size:(NSInteger)size;

+ (void)save;
// 静态load方法，每次启动会被自动调用
+ (void)load;

@end
