//
//  NSMantleClassCreater.h
//  
//
//  Created by heke on 16/1/31.
//  Copyright © 2016年 mhk. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kMantle_h_File @"kMantle_h_File"
#define kMantle_m_File @"kMantle_m_File"

@interface NSMantleClassCreater : NSObject

+ (NSDictionary *)createMantleClassFromJsonString:(NSString *)jsonString
                                    mainClassName:(NSString *)className;

+ (NSDictionary *)createMantleClassFromJsonDictionary:(NSDictionary *)jsonDic
                                        mainClassName:(NSString *)className;

@end
