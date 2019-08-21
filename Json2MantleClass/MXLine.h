//
//  MXLine.h
//  Frame2Flexbox
//
//  Created by heke on 2019/7/26.
//  Copyright © 2019 HeKe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class MXLine;

MXLine *line__(NSString *content, NSInteger level);

@interface MXLine : NSObject

+ (instancetype)lineWith:(NSString *)content indent:(NSInteger)spaceCount;
/**
 indent = level * 4
 */
+ (instancetype)lineWith:(NSString *)content level:(NSInteger)level;

@property (nonatomic, copy) NSString *lineValue;

@end

NS_ASSUME_NONNULL_END
