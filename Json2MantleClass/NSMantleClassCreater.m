//
//  NSMantleClassCreater.m
//  
//
//  Created by heke on 16/1/31.
//  Copyright © 2016年 mhk. All rights reserved.
//

#import "NSMantleClassCreater.h"
#import "NSString+TMSerialize.h"

#define kDemoJson @"{\"errorCode\":0}"

NSString *const kMantleHeader = @"#import \"Mantle.h\"\n";
NSString *const kCustomHeader = @"#import \"%@.h\"\n";

NSString *const kMantleInterfaceBeginFormat = @"@interface %@ : MTLModel<MTLJSONSerializing>\n";
NSString *const kImplementationFormat = @"@implementation %@\n";
NSString *const kEnd = @"@end\n";
NSString *const rn   = @"\n";

NSString *const kassignFormat = @"@property (nonatomic, assign) %@ %@;\n";
NSString *const kcopyFormat   = @"@property (nonatomic, copy)   %@ *%@;\n";
NSString *const kstrongFormat = @"@property (nonatomic, strong) %@ *%@;\n";

NSString *const kType_String    = @"NSString";
NSString *const kType_CGFloat   = @"CGFloat";
NSString *const kType_BOOL      = @"BOOL";
NSString *const kType_NSInteger = @"NSInteger";
NSString *const kType_NSArray   = @"NSArray";
NSString *const kType_NSDictionary = @"NSDictionary/*此处类型需使用者重新定义*/";
NSString *const kType_id = @"id";

NSString *const kReturn = @"return ";

NSString *const kDicBegin = @"@{";
NSString *const kDicEnd   = @"}";
NSString *const kArrayBegin = @"@[";
NSString *const kArrayEnd   = @"]";

NSString *const kPropertyKey = @"   @\"%@\":@\"%@\"";

NSString *const kPropertyKeyMapFuncBegin = @"+ (NSDictionary *)JSONKeyPathsByPropertyKey {\n";
NSString *const kValueTransformerFuncBegin = @"+ (NSValueTransformer *)%@JSONTransformer {\n";
NSString *const kFuncEnd = @"}\n";

NSString *const kBaseValueTransformerFunc = @"+ (NSValueTransformer *)%@JSONTransformer {\n\
    return [MTLValueTransformer transformerUsingForwardBlock:^id(id rawValue, BOOL *success, NSError *__autoreleasing *error) \n{\
        return rawValue;\n\
    }];\n\
}\n";

NSString *const kDictionaryValueTransformerFunc = @"+ (NSValueTransformer *)%@JSONTransformer {\n\
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:%@.class];\n\
}\n";

NSString *const kArrayValueTransformerFunc = @"+ (NSValueTransformer *)%@JSONTransformer {\n\
    return [MTLJSONAdapter arrayTransformerWithModelClass:%@.class];\n\
}\n";

NSString *const initWithDictionaryFunc = @"- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error {\n\
    self = [super initWithDictionary:dictionaryValue error:error];\n\
    if (self) {\n\
        \n\
    }\n\
    return self;\n\
}\n";

@implementation NSMantleClassCreater

+ (void)doTest {
    NSDictionary *resultDic = [NSMantleClassCreater createMantleClassFromJsonString:kDemoJson
                                                                      mainClassName:@"TMPost"];
    NSLog(@"%@",resultDic);
}

+ (NSDictionary *)createMantleClassFromJsonString:(NSString *)jsonString
                                    mainClassName:(NSString *)className {
    if (jsonString.length<1) {
        return nil;
    }
    
    NSDictionary *dic = [jsonString tm_jsonDic];
    if ([dic count]<1) {
        return nil;
    }
    
    NSDictionary *resultDic = [NSMantleClassCreater createMantleClassFromJsonDictionary:dic
                                                                          mainClassName:className];
    return resultDic;
}

/*
 头文件统一生成，每个单独的类实现中不用包括头文件
 */
+ (NSDictionary *)createMantleClassFromJsonDictionary:(NSDictionary *)jsonDic
                                        mainClassName:(NSString *)className {
    //头文件中包含文件
    NSString *headerFileHeader = @"#import <Mantle/Mantle.h>\n";
    //实现文件中的包含文件
    NSString *implementHeader = [NSString stringWithFormat:kCustomHeader,className];
    
    NSMutableString *headerFile = [NSMutableString string];
    NSMutableString *mFile      = [NSMutableString string];
    [headerFile appendString:headerFileHeader];[headerFile appendString:rn];
    [mFile appendString:implementHeader];[mFile appendString:rn];
    
    NSMutableArray *headerFiles = [NSMutableArray array];
    NSMutableArray *mFiles      = [NSMutableArray array];
    
    [NSMantleClassCreater createHeaderFileOfClass:className of:jsonDic storeIn:headerFiles];
    [NSMantleClassCreater createMFileOfClass:className of:jsonDic storeIn:mFiles];
    
    NSEnumerator *enumerator=[headerFiles reverseObjectEnumerator];//得到集合的倒序迭代器
    id obj = nil;
    while(obj=[enumerator nextObject]){
        [headerFile appendString:(NSString *)obj];
    }
    
    [mFiles enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [mFile appendString:(NSString *)obj];
    }];
    
    return @{kMantle_h_File:headerFile,
             kMantle_m_File:mFile};
}

+ (void)createHeaderFileOfClass:(NSString *)className of:(NSDictionary *)jsonDic storeIn:(NSMutableArray *)bags{
    if ([jsonDic count]<1) {
        return;
    }
    
    NSArray *keys = [jsonDic allKeys];
    
    NSMutableString *HeaderFile = [NSMutableString string];
    
    //create header file here
    [HeaderFile appendString:rn];
    [HeaderFile appendString:[NSString stringWithFormat:kMantleInterfaceBeginFormat,className]];
    [HeaderFile appendString:rn];
    for (NSString *key in keys) {
        [HeaderFile appendString:[NSMantleClassCreater getPropertyOfKey:key ofClass:className fromDictionary:jsonDic]];
    }
    [HeaderFile appendString:rn];
    [HeaderFile appendString:kEnd];
    [HeaderFile appendString:rn];
    
    [bags addObject:HeaderFile];
    id value = nil;
    for (NSString *key in keys) {
        value = [jsonDic valueForKey:key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            [NSMantleClassCreater createHeaderFileOfClass:[NSString stringWithFormat:@"%@_%@",className,key] of:value storeIn:bags];
        }else if ([value isKindOfClass:[NSArray class]]) {
            value = [(NSArray *)value firstObject];
            if ([value isKindOfClass:[NSDictionary class]]) {
                [NSMantleClassCreater createHeaderFileOfClass:[NSString stringWithFormat:@"%@_%@",className,key] of:value storeIn:bags];
            }
        }
    }
}

+ (void)createMFileOfClass:(NSString *)className of:(NSDictionary *)jsonDic  storeIn:(NSMutableArray *)bags{
    if ([jsonDic count]<1) {
        return;
    }
    
    NSArray *keys = [jsonDic allKeys];
    
    NSMutableString *MFile = [NSMutableString string];
    
    //add implementation begin
    [MFile appendString:[NSString stringWithFormat:kImplementationFormat,className]];
    
    //add property key map
    [MFile appendString:kPropertyKeyMapFuncBegin];
        [MFile appendString:kReturn];
    
        [MFile appendString:kDicBegin];
        NSInteger index = 0;
        NSInteger count = [keys count];
        for (NSString *key in keys) {
            
            [MFile appendString:[NSString stringWithFormat:kPropertyKey,key,key]];
            if (index<count-1) {
                [MFile appendString:@",\n"];
            }
            
            index++;
        }
        [MFile appendString:kDicEnd];[MFile appendString:@";\n"];
    
    [MFile appendString:kFuncEnd];
    [MFile appendString:rn];
    
    //add initWithDictionaryFunc
    [MFile appendString:initWithDictionaryFunc];
    id value = nil;
    id value1 = nil;
    for (NSString *key in keys) {
        value = [jsonDic valueForKey:key];
        if ([value isKindOfClass:[NSArray class]]) {
//            value1 = [(NSArray *)value firstObject];
//            if ([value1 isKindOfClass:[NSDictionary class]]) {
//                [MFile appendString:[NSString stringWithFormat:kDictionaryValueTransformerFunc,key,[NSString stringWithFormat:@"%@_%@",className,key]]];
//            }else{
            [MFile appendString:[NSString stringWithFormat:kArrayValueTransformerFunc,key,[NSString stringWithFormat:@"%@_%@",className,key]]];
//            }
        }else if ([value isKindOfClass:[NSDictionary class]]){
            [MFile appendString:[NSString stringWithFormat:kDictionaryValueTransformerFunc,key,[NSString stringWithFormat:@"%@_%@",className,key]]];
        }else {
            [MFile appendString:[NSString stringWithFormat:kBaseValueTransformerFunc,key]];
        }
    }
    //
    
    //add implementation end
    [MFile appendString:kEnd];
    [MFile appendString:rn];
    
    [bags addObject:MFile];
    
    for (NSString *key in keys) {
        value = [jsonDic valueForKey:key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            [NSMantleClassCreater createMFileOfClass:[NSString stringWithFormat:@"%@_%@",className,key] of:value storeIn:bags];
        }else if ([value isKindOfClass:[NSArray class]]) {
            value1 = [(NSArray *)value firstObject];
            if ([value1 isKindOfClass:[NSDictionary class]]) {
                [NSMantleClassCreater createMFileOfClass:[NSString stringWithFormat:@"%@_%@",className,key] of:value1 storeIn:bags];
            }
        }
    }
}

+ (NSString *)getPropertyOfKey:(NSString *)key ofClass:(NSString *)className fromDictionary:(NSDictionary *)aDic {
    id aValue = [aDic valueForKey:key];
    
    NSString *varName = key;
    NSString *format = nil;
    NSString *typeName = nil;
    
    if ([aValue respondsToSelector:@selector(objCType)]) {//标量 整形、浮点、bool
        if (strcmp([aValue objCType], @encode(long long)) == 0) {//整形
            typeName = kType_NSInteger;
        }else if (strcmp([aValue objCType], @encode(double)) == 0) {//浮点
            typeName = kType_CGFloat;
        }else if (strcmp([aValue objCType], @encode(char)) == 0) {//bool
            typeName = kType_BOOL;
        }
        format = kassignFormat;
    }else{
        if ([aValue isKindOfClass:[NSString class]]) {//字符串
            typeName = kType_String;
            format = kcopyFormat;
        }else if ([aValue isKindOfClass:[NSArray class]]){//数组
            typeName = kType_NSArray;
            format = kstrongFormat;
        }else if ([aValue isKindOfClass:[NSDictionary class]]){//字典
            typeName = [NSString stringWithFormat:@"%@_%@",className,key];//kType_NSDictionary;
            format = kstrongFormat;
        }else{//未知类型
            typeName = kType_id;
            format = kassignFormat;
        }
    }
    return [NSString stringWithFormat:format,typeName,varName];
}

@end
