//
//  KConfig.h
//  KacheDemo
//
//  Created by jiajun on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define     KACHE_DEFAULT_POOL_SIZE     20
#define     KACHE_DEFAULT_QUEUE_SIZE    10

// Default expired time, 10 Days.
#define     KACHE_DEFAULT_LIFE_DURATION 864000

// 把内存归档到磁盘的阈值，单位 byte
#define ARCHIVING_THRESHOLD             50000