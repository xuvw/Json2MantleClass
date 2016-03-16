//
//  AppDelegate.m
//  Json2MantleClass
//
//  Created by heke on 2/2/16.
//  Copyright © 2016年 mhk. All rights reserved.
//

#import "AppDelegate.h"
#import "NSMantleClassCreater.h"
#import <AppKit/AppKit.h>

#define SeperatorHLine @"\n===========================================================================\n"

@interface AppDelegate ()
<NSWindowDelegate>

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)windowWillClose:(NSNotification *)notification {
    [NSApp terminate:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.window.delegate = self;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}
- (IBAction)doConvert:(NSButton *)sender {
    
    [self.bottomTextView.textStorage deleteCharactersInRange:NSMakeRange(0,self.bottomTextView.textStorage.string.length)];
    
    NSString *rawJson = self.topTextView.textStorage.string;
    NSString *mainClass = self.textField.stringValue;
    
    NSDictionary *result = [NSMantleClassCreater createMantleClassFromJsonString:rawJson mainClassName:mainClass];
    
    NSString *headerFile = result[kMantle_h_File];
    NSString *mFile      = result[kMantle_m_File];
    if (headerFile.length<1 || mFile.length<1) {
        [self.bottomTextView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"解析失败"]];
        return;
    }
    
    [self.bottomTextView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:headerFile]];
    [self.bottomTextView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:SeperatorHLine]];
    [self.bottomTextView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:mFile]];
}

@end
