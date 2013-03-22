kache
=====

iOS缓存控件，支持哈希，队列和时间池。

Kache提供了一套数据缓存方案。无缓存场景下，数据从远程服务器加载到客户端，生成数据对象供客户端应用使用。

使用Kache作为应用的缓存方案，流程则为：每次需要加载数据之前，开发者先从Kache中获取数据

若Kache返回一个空值则证明该缓存项不存在，需要再次从远程服务器获取数据，数据返回，生成数据对象的同时，通过Kache存入缓存，供下次使用；

若Kache返回数据，则可直接生成数据对象。

使用方法
=============
import Kache的头文件 KCH.h

```
#import "KCH.h"
```
Kache的每个实例是一个缓存空间不同的缓存空间互相独立。开发者可以单独初始化Kache实例对象，并指定FileToken作为标记，或直接使用Kache提供的静态方法，操作默认空间。
Kache提供的所有静态方法，都有对应Kache的实例方法。

添加缓存
把ID为“123456”的一个数据“ThisIsADemoData.”存入缓存，1小时候过期。

```
[Kache setValue:@"ThisIsADemoData" forKey:@"123456" expiredAfter:3600];
```

取出KEY为“123456”的数据，并打印。

```
NSString *demoData = [Kache valueForKey:@"123456"];
NSLog(@"Data:%@", demoData);
```

使用KPool。KPool提供了一个可变大小的缓存池，原理是：当存入Pool中的对象超过配置文件中配置的KACHE_DEFAULT_POOL_SIZE，则最早过期的一个将被清除。自己定义的Pool可以指定这个值。
一个缓存控件内可以使用多个Pool，开发者可以选择自己定义或使用默认的。
读取Pool中的值与普通对象一样。

```
[Kache setValue:@"PoolValue1" inDefaultPoolForKey:@"key_1_in_pool" expiredAfter:0];
```

使用KQueue。KQueue提供了一个可变大小的缓存队列。与KPool一样，开发者可以选择使用默认或自定义的。
KQueue中的对象不允许指定过期时间，全部使用默认值，切没有KEY，只能通过push方法存入和pop方法获取。

```
[Kache pushValue:@"inQueue1"]; // 队列：{"inQueue1"}
[Kache pushValue:@"inQueue2"]; // 队列：{"inQueue1", "inQueue2"}
[Kache pushValue:@"inQueue3"]; // 队列：{"inQueue1", "inQueue2", "inQueue3"}

NSLog(@"%@", [Kache popValue]); // 打印 "inQueue1", 队列：{"inQueue2", "inQueue3"}

```

调用save方法把缓存空间归档，调用load方法重新载入

```
[Kache save]; // 归档
[Kache load]; // 重新载入，每次启动自动调用
```

具体使用方法可参考工程中的Demo，或 iOSSF 项目：[https://github.com/gaosboy/iOSSF](https://github.com/gaosboy/iOSSF) 

配置文件
=============
### kache.conf
通过修改配置文件可以改变Kache控件的工作状态

```
#define     KACHE_DEFAULT_POOL_SIZE     20
#define     KACHE_DEFAULT_QUEUE_SIZE    10

// Default expired time, 10 Days.
#define     KACHE_DEFAULT_LIFE_DURATION 864000

// 把内存归档到磁盘的阈值，单位 byte
#define ARCHIVING_THRESHOLD             50000
 ```
