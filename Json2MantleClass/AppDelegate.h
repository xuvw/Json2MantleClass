//
//  AppDelegate.h
//  Json2MantleClass
//
//  Created by heke on 2/2/16.
//  Copyright © 2016年 mhk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSScrollView *TextView;
@property (weak) IBOutlet NSButton *convertButton;
@property (unsafe_unretained) IBOutlet NSTextView *topTextView;
@property (unsafe_unretained) IBOutlet NSTextView *bottomTextView;
@property (weak) IBOutlet NSTextField *textField;

@end

