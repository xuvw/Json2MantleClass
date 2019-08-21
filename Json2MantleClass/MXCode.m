//
//  MXCode.m
//  Frame2Flexbox
//
//  Created by heke on 2019/7/26.
//  Copyright © 2019 HeKe. All rights reserved.
//

#import "MXCode.h"

@interface MXCode ()

@property (nonatomic, strong) NSMutableArray *codelist;

@end

@implementation MXCode

- (instancetype)init
{
    self = [super init];
    if (self) {
        _codelist = @[].mutableCopy;
    }
    return self;
}

- (void)addLine:(MXLine *)line {
    [_codelist addObject:line];
}

- (NSString *)codeString {
    NSMutableString *mStr = [[NSMutableString alloc] init];
    
    for (MXLine *line in _codelist) {
        [mStr appendString:[line lineValue]];
    }
    return mStr;
}

@end
