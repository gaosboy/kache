//
//  KHolder.m
//  KacheDemo
//
//  Created by jiajun on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define Kache_Objects_Disk_Path         @"Kache_objects"
#define DATA_FREE                       0
#define DATA_OPERATING                  1

#import "KConfig.h"
#import "KHolder.h"
#import "KObject.h"
#import "KUtil.h"

@interface KHolder ()

// 正在进行归档的状态位
@property (assign, atomic)      BOOL                        archiving;
@property (assign, atomic)      BOOL                        cleaning;
@property (strong, nonatomic)   NSFileManager               *fileManager;
@property (strong, atomic)      NSMutableArray              *keys;
@property (assign, nonatomic)   NSUInteger                  size;
@property (strong, nonatomic)   NSMutableDictionary         *objects;
@property (strong, nonatomic)   NSString                    *path;
@property (strong, atomic)      NSConditionLock             *lock;

// 把数据写到磁盘
- (void)doArchive;
- (void)archiveData;
- (void)archiveAllData;

- (void)doClean;
- (void)cleanExpiredObjects;

@end

@implementation KHolder

@synthesize archiving   = _archiving;
@synthesize cleaning    = _cleaning;

@synthesize fileManager = _fileManager;
// 缓存Key列表
@synthesize keys        = _keys;
// 缓存大小
@synthesize size        = _size;
// 缓存内容
@synthesize objects     = _objects;

@synthesize path        = _path;

#pragma mark - init

- (id)init
{
    self = [self initWithToken:@"_KacheDefault"];
    if (self) {
        return self;
    }

    return nil;
}

- (id)initWithToken:(NSString *)token
{
    self = [super init];
    if (self) {
        self.objects = [[NSMutableDictionary alloc] init];
        self.keys = [[NSMutableArray alloc] init];
        self.size = 0;
        self.lock = [[NSConditionLock alloc] initWithCondition:DATA_OPERATING];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *libDirectory = [paths objectAtIndex:0];
        self.path = [libDirectory stringByAppendingPathComponent:[Kache_Objects_Disk_Path stringByAppendingPathExtension:token]];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self doArchive];
        });
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [self doClean];
        });

        return self;
    }

    return nil;
}

#pragma mark - private

- (NSFileManager *)fileManager
{
    return [NSFileManager defaultManager];
}

- (void)doArchive
{
    NSTimer *archivingTimer = [NSTimer timerWithTimeInterval:10.f target:self selector:@selector(archiveData) userInfo:nil repeats:YES];
    NSRunLoop *archivingRunloop = [NSRunLoop currentRunLoop];
    [archivingRunloop addTimer:archivingTimer forMode:NSDefaultRunLoopMode];
    while (YES) {
        [archivingRunloop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:2.f]];
    }
}

- (void)archiveData
{
    self.archiving = YES;
    NSLog(@"archiging...");
       if (0 < ARCHIVING_THRESHOLD
           && ARCHIVING_THRESHOLD < self.size) {
           BOOL isDirectory = NO;
           if (! [[NSFileManager defaultManager] fileExistsAtPath:self.path isDirectory:&isDirectory]) {
               [self.fileManager createDirectoryAtPath:self.self.path
                           withIntermediateDirectories:YES
                                            attributes:nil
                                                 error:nil];
           }
           [self.lock lockWhenCondition:DATA_FREE];
           NSMutableArray *copiedKeys = [self.keys mutableCopy];
           while (0 < [copiedKeys count]) {
               // 归档至阈值一半的数据
               if ((ARCHIVING_THRESHOLD / 2) >= self.size) {
                   break;
               }
               NSString *key = [copiedKeys lastObject];
               NSString *filePath = [self.path stringByAppendingPathComponent:key];
               
               NSData *data = [self.objects objectForKey:key];
               [data writeToFile:filePath atomically:YES];
               self.size -= data.length;
               [copiedKeys removeLastObject];
               [self.objects removeObjectForKey:key];
           }
           copiedKeys = nil;
           [self.lock unlockWithCondition:DATA_FREE];
       }
    self.archiving = NO;
}

- (void)archiveAllData
{
    self.archiving = YES;
    BOOL isDirectory = NO;
    if (! [[NSFileManager defaultManager] fileExistsAtPath:self.path isDirectory:&isDirectory]) {
        [self.fileManager createDirectoryAtPath:self.self.path
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:nil];
    }
    NSMutableArray *copiedKeys = [self.keys mutableCopy];
    while (0 < [copiedKeys count]) {
        NSString *key = [copiedKeys lastObject];
        NSString *filePath = [self.path stringByAppendingPathComponent:key];
        
        NSData *data = [self.objects objectForKey:key];
        [data writeToFile:filePath atomically:YES];
        self.size -= data.length;
        [copiedKeys removeLastObject];
        [self.objects removeObjectForKey:key];
    }
    copiedKeys = nil;
    self.archiving = NO;
}

- (void)doClean
{
    NSTimer *cleaningTimer = [NSTimer timerWithTimeInterval:30.f target:self selector:@selector(cleanExpiredObjects) userInfo:nil repeats:YES];
    NSRunLoop *cleaningRunloop = [NSRunLoop currentRunLoop];
    [cleaningRunloop addTimer:cleaningTimer forMode:NSDefaultRunLoopMode];
    while (YES) {
        [cleaningRunloop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:2.f]];
    }
}

- (void)cleanExpiredObjects
{
    NSLog(@"cleaning...");
    self.cleaning = YES;
    if (self.keys && 0 < [self.keys count]) {
        [self.lock lock];
        for (int i = 0; i < [self.keys count] - 1; i ++) {
            NSString *tmpKey = [self.keys objectAtIndex:i];
            KObject *leftObject = [self objectForKey:tmpKey];
            if ([leftObject expiredTimestamp] < [KUtil nowTimestamp]) {
                [self removeObjectForKey:tmpKey];
            }
            else {
                break;
            }
        }
        [self.lock unlockWithCondition:DATA_FREE];
    }
    self.cleaning = NO;
}

#pragma mark - public

- (void)removeObjectForKey:(NSString *)key {
    [self.keys removeObject:key];
    if ([[self.objects allKeys] containsObject:key]) {
        [self.objects removeObjectForKey:key];
    }
    else {
        NSString *filePath = [self.path stringByAppendingPathComponent:key];
        [self.fileManager removeItemAtPath:filePath error:nil];
    }
}

- (void)setValue:(id)value forKey:(NSString *)key expiredAfter:(NSInteger)duration
{
    KObject *object = [[KObject alloc] initWithData:value andLifeDuration:duration];
    
    if (self.archiving) {
        NSString *filePath = [self.path stringByAppendingPathComponent:key];
        [object.data writeToFile:filePath atomically:YES];
    }
    else {
        [self.objects setValue:object.data forKey:key];
        self.size += [object size];
    }
    
    // TODO sort the key by expired time.
    [self.keys removeObject:key];
    
    [self.lock lockWhenCondition:DATA_FREE];
    for (int i = [self.keys count] - 1; i >= 0; i --) {
        NSString *tmpKey = [self.keys objectAtIndex:i];
        KObject *leftObject = [self objectForKey:tmpKey];
        // 过期时间越晚
        if ([leftObject expiredTimestamp] <= [object expiredTimestamp]) {
            if (([self.keys count] - 1) == i) {
                [self.keys addObject:key];
            }
            else {
                [self.keys insertObject:key atIndex:i + 1];
            }
            break;
        }
    }
    [self.lock unlockWithCondition:DATA_FREE];
    if (! [self.keys containsObject:key]) {
        [self.keys insertObject:key atIndex:0];
    }
    
    // 超过阈值，归档
    if ((! self.archiving)
        && 0 < ARCHIVING_THRESHOLD
        && ARCHIVING_THRESHOLD < self.size) {
        [self archiveData];
    }
}

- (id)valueForKey:(NSString *)key
{
    KObject *object = [self objectForKey:key];
    if (object && ! [object expired]) {
        return [object value];
    }
    // No such object.
    return nil;
}

- (KObject *)objectForKey:(NSString *)key
{
    if (! [[self.objects allKeys] containsObject:key]) {
        NSString *filePath = [self.path stringByAppendingPathComponent:key];
        if ([self.fileManager fileExistsAtPath:filePath isDirectory:NO]) {
            // 超过阈值直接返回，不装入内存
            if ((! self.archiving) && 0 < ARCHIVING_THRESHOLD && ARCHIVING_THRESHOLD < self.size) {
                return [[KObject alloc] initWithData:[NSData dataWithContentsOfFile:filePath]];
            }
            else {
                NSData *data = [NSData dataWithContentsOfFile:filePath];
                [self.objects setValue:data forKey:key];
                self.size += data.length;
                data = nil;
                [self.fileManager removeItemAtPath:filePath error:nil];
            }
        }
        else {
            return nil;
        }
    }
    return [[KObject alloc] initWithData:[self.objects objectForKey:key]];
}

// Convert object to NSDictionary.
- (NSDictionary *)serialize
{
    [self archiveAllData];
    return [NSDictionary dictionaryWithObjectsAndKeys:
            self.keys, @"keys",
            [NSString stringWithFormat:@"%d", self.size], @"size",
            nil];
}

// Convert NSDictionary to object.
- (void)unserializeFrom:(NSDictionary *)dict
{
    if ([[dict allKeys] containsObject:@"keys"]
        && [[dict allKeys] containsObject:@"meta"]) {
        self.keys = [dict objectForKey:@"keys"];
        self.size = [[dict objectForKey:@"size"] intValue];
    }
}

@end
