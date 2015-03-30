//
//  GlanceController.h
//  Lets-Build-OTPublisher WatchKit Extension
//
//  Created by Sridhar on 25/03/15.
//  Copyright (c) 2015 TokBox, Inc. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface GlanceController : WKInterfaceController
@property (weak, nonatomic) IBOutlet WKInterfaceImage *interfaceImage;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *interfaceGroup;

@end
