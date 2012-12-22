//
//  KCHMainViewController.m
//  KacheDemo
//
//  Created by jiajun on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "KCHMainViewController.h"

#import "KCH.h"

@interface KCHMainViewController ()

@property (strong, nonatomic) Kache         *kache;
@property (strong, nonatomic) UILabel       *banner;
@property (strong, nonatomic) UILabel       *body;
@property (strong, nonatomic) UIScrollView  *bodyBackground;
@property (assign, nonatomic) NSInteger     offset;
@property (assign, nonatomic) NSInteger     timmer;
@property (assign, nonatomic) NSInteger     counter;

@end

@implementation KCHMainViewController

@synthesize kache                           = _kache;
@synthesize banner                          = _banner;
@synthesize body                            = _body;
@synthesize bodyBackground                  = _bodyBackground;
@synthesize offset                          = _offset;
@synthesize timmer                          = _timmer;
@synthesize counter                         = _counter;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

        self.kache      = [[Kache alloc] init];
        self.timmer     = 0;
        self.offset     = 0;

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.banner = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 10.0f, 320.0f, 20.0f)];
    self.banner.backgroundColor = [UIColor clearColor];
    self.banner.textAlignment = UITextAlignmentCenter;
    self.banner.font = [UIFont boldSystemFontOfSize:18];
    [self.view addSubview:self.banner];
    
    self.body = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 410.0f)];
    self.body.backgroundColor = [UIColor clearColor];
    self.body.numberOfLines = 0;
    self.body.lineBreakMode = UILineBreakModeWordWrap;
    self.body.textAlignment = UITextAlignmentLeft;
    self.body.text = @"";
    [self.body sizeToFit];
    self.body.frame = CGRectMake(0.0f, 0.0f, 300.0f, self.body.bounds.size.height);
    
    [self countDown];
    [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(countDown) userInfo:nil repeats:YES];

    self.bodyBackground = [[UIScrollView alloc] initWithFrame:CGRectMake(10.0f, 40.0f, 320.0f, 410.0f)];
    self.bodyBackground.contentSize = CGSizeMake(300.0f, self.body.bounds.size.height);
    
    [self.bodyBackground addSubview:self.body];
    [self.view addSubview:self.bodyBackground];

    NSInteger delay = 1.0f;
    // Begin Test.
    [self printLog:@"===== Test Begin ====="];
    [self performSelector:@selector(simpleTest) withObject:nil afterDelay:delay];   delay += 12;
    [self performSelector:@selector(queueTest) withObject:nil afterDelay:delay];    delay += 13;
    [self performSelector:@selector(poolTest) withObject:nil afterDelay:delay];     delay += 8;

    [self performSelector:@selector(saveTest) withObject:nil afterDelay:delay];     delay += 7;
    [self performSelector:@selector(loadTest) withObject:nil afterDelay:delay];      delay += 5;

    [self performSelector:@selector(printLog:) withObject:@"===== All Test Done =====" afterDelay:delay];
}

- (void)simpleTest
{
    [self printLog:@"====== Begin Simple Test. ======"];
    // Set Simple Cache.
    [self printLog:@"Set 12 Simple Cache Value:\nkey_0 ~ key_11."];
    
    for (int i = 0; i < 12; i ++) {
        // After (i+3) seconds, the value will be expired.
        [self.kache setValue:[NSString stringWithFormat:@"ValueWithLifeDuration-%d-AndOffset-%d", i + 3, i]
                      forKey:[NSString stringWithFormat:@"key_%d", i]
                expiredAfter:i + 3];
    }
        
    [self performSelector:@selector(performPrintValue:) withObject:@"key_1" afterDelay:1.0f];
    [self performSelector:@selector(performPrintValue:) withObject:@"key_5" afterDelay:2.0f];
    
    [self performSelector:@selector(printLog:)
               withObject:@"Waiting..."
               afterDelay:3.0f];
    
    [self performSelector:@selector(printLog:)
               withObject:@"After 5 seconds.\nObject: \"key_1\" has been expired."
               afterDelay:4.0f];
    [self performSelector:@selector(performPrintValue:) withObject:@"key_1" afterDelay:5.0f];

    [self performSelector:@selector(printLog:)
               withObject:@"After 10 seconds.\nObject: \"key_5\" has been expired."
               afterDelay:9.0f];
    [self performSelector:@selector(performPrintValue:) withObject:@"key_5" afterDelay:10.0f];
}

- (void)queueTest
{
    [self printLog:@"====== Begin Queue Test. ======"];
    // Set a Queue with Default Size 10.
    [self printLog:@"Push 10 values to the default queue."];

    [self.kache newQueueWithName:@"for_test_queue" size:10];
    for (int i = 0; i < 10; i ++) {
        [self.kache pushValue:[NSString stringWithFormat:@"QueueValue-%d", i] toQueue:@"for_test_queue"]; // Default Queue.
    }

    for (int i = 0; i < 11; i ++) {
        [self performSelector:@selector(printLog:)
                   withObject:[NSString stringWithFormat:@"Pop a Value:\n\"%@\"", [self.kache popFromQueue:@"for_test_queue"]]
                   afterDelay:i + 1];
    }
}

- (void)poolTest
{
    [self printLog:@"====== Begin Pool Test. ======"];
    // Pool Test
    [self printLog:@"Set 10 values to the default pool."];
    
    [self.kache newPoolWithName:@"for_test_pool" size:10];
    for (int i = 0; i < 10; i ++) {
        // After (i+3) seconds, the value will be expired.
        [self.kache setValue:[NSString stringWithFormat:@"PoolValue-Offset-%d", i]
                      inPool:@"for_test_pool"
                      forKey:[NSString stringWithFormat:@"pool_key_%d", i]
                expiredAfter:i + 3];
    }
    
    [self performSelector:@selector(printLog:)
               withObject:[NSString stringWithFormat:@"Value of pool_key_0: \"%@\"", [self.kache valueForKey:@"pool_key_0"]]
               afterDelay:1.0f];
    [self performSelector:@selector(printLog:)
               withObject:[NSString stringWithFormat:@"Value of pool_key_1: \"%@\"", [self.kache valueForKey:@"pool_key_1"]]
               afterDelay:2.0f];

    [self performSelector:@selector(printLog:)
               withObject:@"Set 2 more value to the Pool."
               afterDelay:3.0f];

    [self.kache setValue:[NSString stringWithFormat:@"PoolValue-Offset-%d", 10]
                  inPool:@"for_test_pool"
                  forKey:[NSString stringWithFormat:@"pool_key_%d", 10]
            expiredAfter:20];
    [self.kache setValue:[NSString stringWithFormat:@"PoolValue-Offset-%d", 11]
                  inPool:@"for_test_pool"
                  forKey:[NSString stringWithFormat:@"pool_key_%d", 11]
            expiredAfter:20];
    
    [self performSelector:@selector(printLog:)
               withObject:@"Value of pool_key_0 and pool_key_1 should be removed."
               afterDelay:4.0f];

    [self performSelector:@selector(printLog:)
               withObject:[NSString stringWithFormat:@"Value of pool_key_0: \"%@\"", [self.kache valueForKey:@"pool_key_0"]]
               afterDelay:5.0f];
    [self performSelector:@selector(printLog:)
               withObject:[NSString stringWithFormat:@"Value of pool_key_1: \"%@\"", [self.kache valueForKey:@"pool_key_1"]]
               afterDelay:6.0f];
}

- (void)saveTest
{
    [self printLog:@"====== Begin Save Test. ======"];
    
    [self printLog:@"Set 10 simple values."];

    for (int i = 0; i < 12; i ++) {
        // expiredAfter:0 means expired after default duration (KACHE_DEFAULT_LIFE_DURATION: 10 days by default.)
        [self.kache setValue:[NSString stringWithFormat:@"SaveNewValueWithLifeDuration-%d-AndOffset-%d", i + 3, i]
                      forKey:[NSString stringWithFormat:@"save_key_%d", i]
                expiredAfter:0];
    }

    [self performSelector:@selector(printLog:)
               withObject:[NSString stringWithFormat:@"Value of \"save_key_0\"\n\"%@\"",
                           [self.kache valueForKey:@"save_key_0"]]
               afterDelay:1.0f];

    [self performSelector:@selector(printLog:) withObject:@"Push 10 values to the Queue." afterDelay:2.0f];

    [self.kache newQueueWithName:@"for_save_test_queue" size:10];
    for (int i = 0; i < 10; i ++) {
        [self.kache pushValue:[NSString stringWithFormat:@"SaveNewQueueValue-%d", i] toQueue:@"for_save_test_queue"];
    }

    [self performSelector:@selector(printLog:)
               withObject:[NSString stringWithFormat:@"Do one Pop:\n\"%@\"",
                           [self.kache popFromQueue:@"for_save_test_queue"]]
               afterDelay:3.0f];
    
    [self performSelector:@selector(printLog:) withObject:@"Set 10 values to the Pool." afterDelay:4.0f];
    
    [self.kache newPoolWithName:@"for_save_test_pool" size:10];
    for (int i = 0; i < 10; i ++) {
        // expiredAfter:0 means expired after default duration (KACHE_DEFAULT_LIFE_DURATION: 10 days by default.)
        [self.kache setValue:[NSString stringWithFormat:@"SaveNewPoolValue-Offset-%d", i]
                      inPool:@"for_save_test_pool"
                      forKey:[NSString stringWithFormat:@"pool_key_%d", i]
                expiredAfter:0];
    }

    [self performSelector:@selector(printLog:)
               withObject:[NSString stringWithFormat:@"Value of \"pool_key_0\"\n\"%@\"",
                           [self.kache valueForKey:@"pool_key_0"]]
               afterDelay:5.0f];

    [self performSelector:@selector(printLog:) withObject:@"Save to Disk." afterDelay:6.0f];

    [self.kache save];
}

- (void)loadTest
{
    [self printLog:@"====== Begin Load Test. ======"];
    
    Kache *tmpKache = [[Kache alloc] init];

    [tmpKache load];
    [self printLog:@"New Kache instance load from disk."];

    [self performSelector:@selector(printLog:)
               withObject:[NSString stringWithFormat:@"Value of \"save_key_0\"\n\"%@\"",
                           [tmpKache valueForKey:@"save_key_0"]]
               afterDelay:1.0f];
        
    [self performSelector:@selector(printLog:)
               withObject:[NSString stringWithFormat:@"Do one Pop:\n\"%@\"",
                           [tmpKache popFromQueue:@"for_save_test_queue"]]
               afterDelay:2.0f];
    
    [self performSelector:@selector(printLog:)
               withObject:[NSString stringWithFormat:@"Value of \"pool_key_0\"\n\"%@\"",
                           [tmpKache valueForKey:@"pool_key_0"]]
               afterDelay:3.0f];
}

- (void)performPrintValue:(NSString *)key
{
    [self printLog:[NSString stringWithFormat:@"Value of %@:\n\"%@\"",
                    key, [self.kache valueForKey:key]]];
}

- (void)countDown
{
    self.banner.text = [NSString stringWithFormat:@"Kache Demo, %d second(s)", self.timmer];
    self.timmer ++;
}

- (void)printLog:(NSString *)log
{
    NSLog(@"%@", log);
    self.body.text = [NSString stringWithFormat:@"%@\n\n%@", log, self.body.text];
    [self.body sizeToFit];
    self.body.frame = CGRectMake(0.0f, 0.0f, 300.0f, self.body.bounds.size.height);
    self.bodyBackground.contentSize = CGSizeMake(300.0f, self.body.bounds.size.height);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
