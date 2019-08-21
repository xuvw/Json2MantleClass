//
//  MXLine.m
//  Frame2Flexbox
//
//  Created by heke on 2019/7/26.
//  Copyright © 2019 HeKe. All rights reserved.
//

#import "MXLine.h"
#define kSpaceString @"                                                                     "

@interface MXLine ()

@property (nonatomic, copy) NSString *content;
@property (nonatomic, assign) NSInteger indent;

@end

@implementation MXLine

+ (instancetype)lineWith:(NSString *)content indent:(NSInteger)spaceCount {
    MXLine *line = [[MXLine alloc] init];
    line.content = content;
    line.indent = spaceCount;
    return line;
}

+ (instancetype)lineWith:(NSString *)content level:(NSInteger)level {
    MXLine *line = [[MXLine alloc] init];
    line.content = content;
    line.indent = level *4;
    return line;
}

- (NSString *)lineValue {
    NSString *space = kSpaceString;
    return [NSString stringWithFormat:@"%@%@\n",[space substringWithRange:NSMakeRange(0, _indent)], _content];
}

@end

MXLine *line__(NSString *content, NSInteger level) {
    return [MXLine lineWith:content level:level];
}
