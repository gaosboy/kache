kache
=====

iOS缓存控件，支持哈希，队列和时间池

使用方法
=============
import Kache的头文件 KCH.h

```
#import "KCH.h"
```

具体使用方法可参考工程中的Demo，或 iOSSF 项目：[https://github.com/gaosboy/iOSSF](https://github.com/gaosboy/iOSSF) 

配置文件
=============
### kache.conf
通过修改配置文件可以改变Kache控件的工作状态

```
// If it is set as 1 it use two level storage. Once more than
// 100 objects stored in memory, the earliest objects will be
// archived to disk storaged.
#define     KACHE_AUTO_ARCH             0
#define     KACHE_ARCH_THREHOLD_VALUE   500

#define     KACHE_DEFAULT_POOL_SIZE     20
#define     KACHE_DEFAULT_QUEUE_SIZE    10

// Default expired time, 10 Days.
#define     KACHE_DEFAULT_LIFE_DURATION 864000

// 把内存归档到磁盘的阈值，单位 byte
#define ARCHIVING_THRESHOLD             50000
 ```
