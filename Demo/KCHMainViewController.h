//
//  KCHMainViewController.h
//  KacheDemo
//
//  Created by jiajun on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Kache;

@interface KCHMainViewController : UIViewController
{
    Kache           *kache;
    UILabel         *banner;
    UILabel         *body;
    UIScrollView    *bodyBackground;
    
    NSInteger       offset;
    NSInteger       timmer;
    
    NSInteger       counter;
}

@end
