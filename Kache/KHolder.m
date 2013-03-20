//
//  KHolder.m
//  KacheDemo
//
//  Created by jiajun on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define Kache_Objects_Disk_Path         @"Caches/Kache_objects"

#import "KConfig.h"
#import "KHolder.h"
#import "KObject.h"
#import "KPool.h"
#import "KQueue.h"
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

// 把数据写到磁盘
- (void)archiveData;
- (void)archiveAllData;

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
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString *libDirectory = [paths objectAtIndex:0];
        self.path = [libDirectory stringByAppendingPathComponent:[Kache_Objects_Disk_Path stringByAppendingPathExtension:token]];
        
        return self;
    }

    return nil;
}

#pragma mark - private

- (NSFileManager *)fileManager
{
    return [NSFileManager defaultManager];
}

- (void)archiveData
{
    self.archiving = YES;
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        BOOL isDirectory = NO;
        if (! [[NSFileManager defaultManager] fileExistsAtPath:self.path isDirectory:&isDirectory]) {
            [self.fileManager createDirectoryAtPath:self.self.path
                        withIntermediateDirectories:YES
                                         attributes:nil
                                              error:nil];
        }
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
        self.archiving = NO;
//    });
}

- (void)archiveAllData
{
    self.archiving = YES;
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
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
//    });
    
}

- (void)cleanExpiredObjects
{
    self.cleaning = YES;
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.keys && 0 < [self.keys count]) {
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
        }
        self.cleaning = NO;
//    });
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
    
    if (! self.cleaning && (0 < [self.keys count])) {
        [self cleanExpiredObjects];
        
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
    }
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
            [self.objects setValue:[NSData dataWithContentsOfFile:filePath] forKey:key];
            [self.fileManager removeItemAtPath:filePath error:nil];
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
