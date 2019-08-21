//
//  MXCode.h
//  Frame2Flexbox
//
//  Created by heke on 2019/7/26.
//  Copyright © 2019 HeKe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MXLine.h"

NS_ASSUME_NONNULL_BEGIN

@interface MXCode : NSObject

- (void)addLine:(MXLine *)line;

- (NSString *)codeString;

@end

NS_ASSUME_NONNULL_END
