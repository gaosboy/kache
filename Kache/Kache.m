//
//  Kache.m
//  KacheDemo
//
//  Created by jiajun on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define KACHE_DEFAULT_POOL_NAME             @"kache_default_pool_name_LKJHGFDWQSFASRTYUIOP:"
#define KACHE_DEFAULT_QUEUE_NAME            @"kache_default_queue_name_QWEDFVHUIOPPLMUYTRDX:"

#import "KConfig.h"
#import "KHolder.h"
#import "KPool.h"
#import "KQueue.h"
#import "Kache.h"

@interface Kache ()

@property (strong, nonatomic)   KHolder                       *holder;
@property (strong, nonatomic)   NSMutableDictionary           *pools;
@property (strong, nonatomic)   NSMutableDictionary           *queues;
@property (assign, nonatomic)   BOOL                          loaded;

@end

@implementation Kache

@synthesize filetoken   = _filetoken;
@synthesize holder      = _holder;
@synthesize pools       = _pools;
@synthesize queues      = _queues;

#pragma mark static for default

+ (Kache *)instance {
    static Kache *obj= nil;
#if defined(__IPHONE_5_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_5_0
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        obj = [[Kache alloc] initWithFiletoken:@""];
    });
#elif defined(__IPHONE_4_3) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_3
	if (nil == obj) {
        obj = [[Kache alloc] initWithFiletoken:@""];
	}
    
#else
#error Your SDK is too old ! Need at least 4.3.
#endif
    if (! obj.loaded) {
        [obj load];
    }
	return obj;
}

+ (void)setValue:(id)value forKey:(NSString *)key expiredAfter:(NSInteger)duration {
    return [[Kache instance] setValue:value forKey:key expiredAfter:duration];
}

+ (void)setValue:(id)value inDefaultPoolForKey:(NSString *)key expiredAfter:(NSInteger)duration {
    return [[Kache instance] setValue:value inPool:nil forKey:key expiredAfter:duration];
}

+ (void)removeObjectForKey:(NSString *)key
{
    return [[Kache instance] removeObjectForKey:key];
}

+ (void)pushValue:(id)value {
    return [[Kache instance] pushValue:value toQueue:nil];
}

+ (id)popValue {
    return [[Kache instance] popFromQueue:nil];
}

+ (id)valueForKey:(NSString *)key {
    return [[Kache instance] valueForKey:key];
}

// Make sure the Pool exsists. Use newPoolWithName:size: to create a new Pool.
+ (void)setValue:(id)value inPool:(NSString *)name forKey:(NSString *)key expiredAfter:(NSInteger)duration {
    return [[Kache instance] setValue:value inPool:name forKey:key expiredAfter:duration];
}

// Make sure the Queue exsists. Use newQueueWithName:size: to create a new Queue.
+ (void)pushValue:(id)value toQueue:(NSString *)name {
    return [[Kache instance] pushValue:value toQueue:name];
}

+ (id)popFromQueue:(NSString *)name {
    return [[Kache instance] popFromQueue:name];
}

+ (void)newQueueWithName:(NSString *)name size:(NSInteger)size {
    return [[Kache instance] newQueueWithName:name size:size];
}

+ (void)newPoolWithName:(NSString *)name size:(NSInteger)size {
    return [[Kache instance] newPoolWithName:name size:size];
}

+ (void)save {
    return [[Kache instance] save];
}

+ (void)load {
// TODO load方法运行在iOS4.3上会挂
//    return [[Kache instance] load];
}

#pragma mark - init

- (id)init
{
    self = [super init];
    if (self) {
        self.queues = [[NSMutableDictionary alloc] init];
        self.pools = [[NSMutableDictionary alloc] init];
        
        self.holder = [[KHolder alloc] initWithToken:@""];
        
        [self newPoolWithName:nil size:0];
        [self newQueueWithName:nil size:0];
        self.filetoken = @"";

        return self;
    }
    return nil;
}

// Spcify a FileToken, Kache will save the data into a different place.
- (id)initWithFiletoken:(NSString *)aFiletoken
{
    self = [super init];
    if (self) {
        self.queues = [[NSMutableDictionary alloc] init];
        self.pools = [[NSMutableDictionary alloc] init];
        
        self.holder = [[KHolder alloc] initWithToken:aFiletoken];
        
        [self newPoolWithName:nil size:0];
        [self newQueueWithName:nil size:0];
        
        self.filetoken = aFiletoken;
        
        return self;
    }
    
    return nil;
}

#pragma mark - public

- (void)setValue:(id)value forKey:(NSString *)key expiredAfter:(NSInteger)duration
{
    [self.holder setValue:value forKey:key expiredAfter:duration];
}

// Make sure the Pool exsists. Use newPoolWithName:size: to create a new Pool.
- (void)setValue:(id)value inPool:(NSString *)name forKey:(NSString *)key expiredAfter:(NSInteger)duration
{
    if (nil == name || 0 >= [name length]) {
        name = KACHE_DEFAULT_POOL_NAME;
    }
    if ([[self.pools allKeys] containsObject:name]) {
        KPool *pool = [self.pools objectForKey:name];
        [pool setValue:value forKey:key expiredAfter:duration];
    }
}

- (void)removeObjectForKey:(NSString *)key
{
    for (NSString *name in [self.pools allKeys]) {
        KPool *pool = [self.pools valueForKey:name];
        [pool removeObjectForKey:key];
    }
    [self.holder removeObjectForKey:key];
}

// Make sure the Queue exsists. Use newQueueWithName:size: to create a new Queue.
- (void)pushValue:(id)value toQueue:(NSString *)name
{
    if (nil == name || 0 >= [name length]) {
        name = KACHE_DEFAULT_QUEUE_NAME;
    }
    if ([[self.queues allKeys] containsObject:name]) {
        KQueue *queue = [self.queues objectForKey:name];
        [queue push:value];
    }
}

- (id)popFromQueue:(NSString *)name
{
    if (nil == name || 0 >= [name length]) {
        name = KACHE_DEFAULT_QUEUE_NAME;
    }
    if ([[self.queues allKeys] containsObject:name]) {
        KQueue *queue = [self.queues objectForKey:name];
        return [queue pop];
    }
    
    return nil;
}

- (id)valueForKey:(NSString *)key
{
    return [self.holder valueForKey:key];
}

- (void)newQueueWithName:(NSString *)name size:(NSInteger)size
{
    if (nil == name || 0 >= [name length]) {
        name = KACHE_DEFAULT_QUEUE_NAME;
    }
    if (! [[self.queues allKeys] containsObject:name]) {
        KQueue *queue = [[KQueue alloc] initWithHolder:self.holder];
        if (0 < size) {
            queue.size = size;
        }
        queue.name = name;
        [self.queues setValue:queue
                       forKey:name];
    }
}

- (void)newPoolWithName:(NSString *)name size:(NSInteger)size;
{
    if (nil == name || 0 >= [name length]) {
        name = KACHE_DEFAULT_POOL_NAME;
    }
    if (! [[self.pools allKeys] containsObject:name]) {
        KPool *pool = [[KPool alloc] initWithHolder:self.holder];
        if (0 < size) {
            pool.size = size;
        }

        pool.name = name;
        [self.pools setValue:pool
                      forKey:name];
    }
}

- (void)save {
    NSMutableArray *queueArray = [[NSMutableArray alloc] init];
    NSMutableArray *poolArray = [[NSMutableArray alloc] init];

    for (KQueue *queue in [self.queues objectEnumerator]) {
        [queueArray addObject:[queue serialize]];
    }
    for (KPool *pool in [self.pools objectEnumerator]) {
        [poolArray addObject:[pool serialize]];
    }

	NSDictionary *kacheDict = [[NSDictionary alloc] initWithObjectsAndKeys:
							   [self.holder serialize],     @"holder",
                               queueArray,                  @"queues",
                               poolArray,                   @"pools",
							   nil];
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *libDirectory = [paths objectAtIndex:0];
	NSString *path = @"KACHE_STORAGE_FILE_QERFCVBJKOL:";
	if (self.filetoken) {
		path = [path stringByAppendingPathExtension:self.filetoken];
	}
	NSString *filePath = [libDirectory stringByAppendingPathComponent:path];
	
	NSData *d = [NSKeyedArchiver archivedDataWithRootObject:kacheDict];
	[d writeToFile:filePath atomically:YES];
}

- (void)load {
    self.loaded = YES;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *libDirectory = [paths objectAtIndex:0];
	
	NSString *path = @"KACHE_STORAGE_FILE_QERFCVBJKOL:";
	if (self.filetoken) {
		path = [path stringByAppendingPathExtension:self.filetoken];
	}
	NSString *filePath = [libDirectory stringByAppendingPathComponent:path];
    
	NSData *d = [NSData dataWithContentsOfFile:filePath];
    if (d && 0 < d.length) {
        NSDictionary *kacheDict = [NSDictionary dictionaryWithDictionary:
                                   [NSKeyedUnarchiver unarchiveObjectWithData:d]];
        
        if (kacheDict && 0 < [kacheDict count]) {
            [self.holder unserializeFrom:[kacheDict objectForKey:@"holder"]];
            for (NSDictionary *queueDict in [kacheDict objectForKey:@"queues"]) {
                KQueue *queue = [[KQueue alloc] initWithHolder:self.holder];
                [queue unserializeFrom:queueDict];
                [self.queues setValue:queue forKey:[queueDict objectForKey:@"name"]];
            }
            for (NSDictionary *poolDict in [kacheDict objectForKey:@"pools"]) {
                KPool *pool = [[KPool alloc] initWithHolder:self.holder];
                [pool unserializeFrom:poolDict];
                [self.pools setValue:pool forKey:[poolDict objectForKey:@"name"]];
            }
        }
    }
}

@end
