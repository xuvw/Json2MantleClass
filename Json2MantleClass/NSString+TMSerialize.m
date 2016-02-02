//
//  NSString+TMSerialize.m
//  Mantle
//
//  Created by heke on 2/2/16.
//  Copyright © 2016年 mhk. All rights reserved.
//

#import "NSString+TMSerialize.h"

@implementation NSString (TMSerialize)

- (NSDictionary *)tm_jsonDic {
    NSError *error = nil;
    NSDictionary *infoDic =
    [NSJSONSerialization JSONObjectWithData: [self dataUsingEncoding:NSUTF8StringEncoding]
                                    options: NSJSONReadingMutableContainers
                                      error: &error];
    if (infoDic && !error) {
        return infoDic;
    }else{
        NSLog(@"%@",error);
        return nil;
    }
}

@end
