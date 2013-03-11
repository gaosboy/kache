//
//  KObject.m
//  KacheDemo
//
//  Created by jiajun on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define KCH_OBJ_DATA        @"data"
#define KCH_OBJ_LIFE        @"life"

#import "KConfig.h"
#import "KObject.h"
#import "KUtil.h"

@interface KObject ()

@property (strong, nonatomic)   NSData                  *data;
@property (strong, nonatomic)   NSMutableDictionary     *object;

@end

@implementation KObject

@synthesize object              = _object;
@synthesize data                = _data;

#pragma mark - init

- (KObject *)initWithData:(id)aData andLifeDuration:(NSInteger)aDuration
{
    self = [super init];

    if (self) {
        aDuration = (0 >= aDuration) ? KACHE_DEFAULT_LIFE_DURATION : aDuration;
        self.data = [NSKeyedArchiver archivedDataWithRootObject:[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                     aData, KCH_OBJ_DATA,
                                                     [NSString stringWithFormat:@"%d", [KUtil expiredTimestampForLife:aDuration]], KCH_OBJ_LIFE,
                                                     nil]];
        return self;
    }
    
    return nil;
}

- (KObject *)initWithData:(NSData *)data
{
    self = [super init];
    
    if (self) {
        self.data = data;
        return self;
    }
    
    return nil;
}

#pragma - public

- (NSData *)data
{
    return _data;
}

- (id)value
{
    if (nil == self.object) {
        self.object = [NSKeyedUnarchiver unarchiveObjectWithData:self.data];
    }
    if ([[self.object allKeys] containsObject:KCH_OBJ_DATA]
        && [self.object objectForKey:KCH_OBJ_DATA]) {
        return [self.object objectForKey:KCH_OBJ_DATA];
    }

    return nil;
}

- (NSInteger)expiredTimestamp
{
    if (nil == self.object) {
        self.object = [NSKeyedUnarchiver unarchiveObjectWithData:self.data];
    }
    return [[self.object objectForKey:KCH_OBJ_LIFE] intValue];
}

- (void)updateLifeDuration:(NSInteger)aDuration
{
    if (nil == self.object) {
        self.object = [NSKeyedUnarchiver unarchiveObjectWithData:self.data];
    }

    aDuration = (0 >= aDuration) ? KACHE_DEFAULT_LIFE_DURATION : aDuration;

    [self.object setValue:[NSString stringWithFormat:@"%d", [KUtil expiredTimestampForLife:aDuration]]
                                          forKey:KCH_OBJ_LIFE];
}

- (BOOL)expired
{
    if (nil == self.object) {
        self.object = [NSKeyedUnarchiver unarchiveObjectWithData:self.data];
    }

    if ([KUtil nowTimestamp] < [[self.object objectForKey:KCH_OBJ_LIFE] intValue]) {
        return NO;
    }

    return YES;
}

- (NSUInteger)size
{
    return _data.length;
}

@end
