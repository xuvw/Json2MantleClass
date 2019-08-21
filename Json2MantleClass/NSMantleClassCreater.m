//
//  NSMantleClassCreater.m
//  
//
//  Created by heke on 16/1/31.
//  Copyright © 2016年 mhk. All rights reserved.
//

#import "NSMantleClassCreater.h"
#import "NSString+TMSerialize.h"
#import "MXCode.h"
#import "MXLine.h"

#define kDemoJson @"{\"errorCode\":0}"

NSString *const kComment = @"\/\/\n\
\/\/  Created by Json2MantleClass\n\
\/\/  Copyright mhk. All rights reserved.\n\
\/\/\n";

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
return [MTLValueTransformer transformerUsingForwardBlock:^id(id rawValue,\n\
                                                             BOOL *success,\n\
                                                             NSError *__autoreleasing *error)\n\
        {\n\
            //NSLog(@\"在这里做类型容错处理\");\n\
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

@interface NSMantleClassCreater ()

@property (nonatomic, strong) MXCode *hCode;
@property (nonatomic, strong) MXCode *mCode;

@end

@implementation NSMantleClassCreater

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

+ (NSDictionary *)createMantleClassFromJsonString:(NSString *)jsonString
                                    mainClassName:(NSString *)className {
    if (jsonString.length<1) {
        return nil;
    }
    
    NSDictionary *dic = [jsonString tm_jsonDic];
    if (!dic) {
        return nil;
    }
    
    NSDictionary *resultDic = [[[NSMantleClassCreater alloc] init] modelCodeFrom:dic className:className];
    
//    [NSMantleClassCreater createMantleClassFromJsonDictionary:dic
//                                                                          mainClassName:className];
    
    return resultDic;
}

/*
 头文件统一生成，每个单独的类实现中不用包括头文件
 
 model代码生成步骤：
 1 生成基本属性代码
 {属性映射表}
 2 生成模型属性OR数组属性
 3 闭合当前模型
 4 是否有字典属性 OR 数组属性
 */
+ (NSDictionary *)createMantleClassFromJsonDictionary:(NSDictionary *)jsonDic
                                        mainClassName:(NSString *)className {
    //头文件中包含文件
    NSString *headerFileHeader = @"#import <Mantle/Mantle.h>\n";
    //实现文件中的包含文件
    NSString *implementHeader = [NSString stringWithFormat:kCustomHeader,className];
    
    NSMutableString *headerFile = [NSMutableString string];
    NSMutableString *mFile      = [NSMutableString string];
    
    [headerFile appendString:kComment];[headerFile appendString:rn];[headerFile appendString:rn];
    [headerFile appendString:headerFileHeader];[headerFile appendString:rn];
    
    [mFile appendString:kComment];[mFile appendString:rn];[mFile appendString:rn];
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

- (NSDictionary *)modelCodeFrom:(NSDictionary *)json
                      className:(NSString *)className {
    
    if (!json || json.count < 1) {
        return nil;
    }
    
    _hCode = [[MXCode alloc] init];
    _mCode = [[MXCode alloc] init];
    
    NSString *clsName = className;
    
    NSString *importHeader = [NSString stringWithFormat:@"#import \"%@.h\"", clsName];
    
    //create head
    [_hCode addLine:line__(@"#import <Mantle/Mantle.h>", 0)];
    [_hCode addLine:line__(@"", 0)];
    
    [_mCode addLine:line__(importHeader, 0)];
    [_mCode addLine:line__(@"", 0)];
    
    //create body
    [self createModelCodeFrom:json className:clsName];
    
    return @{kMantle_h_File:[_hCode codeString],
             kMantle_m_File:[_mCode codeString]};
}

- (void)createModelCodeFrom:(NSDictionary *)json
                  className:(NSString *)className {
    if (!json) {
        return;
    }
    
    if (json.count < 1) {
        NSLog(@"catch.....");
    }
    
    NSString *clsName = className;
    
    
    NSMutableDictionary *keyMap = @{}.mutableCopy;
    NSMutableDictionary *keyClassMap = @{}.mutableCopy;
    NSMutableDictionary *objJson = @{}.mutableCopy;
    
    NSArray *allKeys = [json allKeys];
    for (NSString *key in allKeys) {
        
        NSString *typeName = [self classNameOfValue:json[key]
                                                key:key
                                          className:className];
        
        NSDictionary *jsonObj = [self jsonObject:json[key]];
        if (jsonObj) {
            [objJson setObject:jsonObj forKey:typeName];
        }
    }
    
    allKeys = [objJson allKeys];
    allKeys = [self sortASC:allKeys];
    for (NSString *key in allKeys) {
        [self createModelCodeFrom:objJson[key] className:key];
    }
    
    //.h
    NSString *begin = [NSString stringWithFormat:@"@interface %@ : MTLModel<MTLJSONSerializing>",
                       clsName];
    [_hCode addLine:line__(begin, 0)];
    allKeys = [json allKeys];
    [keyMap removeAllObjects];
    allKeys = [self sortASC:allKeys];
    for (NSString *key in allKeys) {
        
        [keyMap setObject:[self checkKey:key] forKey:key];
        
        NSString *typeName = [self classNameOfValue:json[key]
                                                key:key
                                          className:className];
        
        [_hCode addLine:line__([self propertyOf:typeName value:json[key] propertyName:keyMap[key]], 0)];
        
        NSDictionary *jsonObj = [self jsonObject:json[key]];
        if (jsonObj.count > 0) {
            [objJson setObject:jsonObj forKey:typeName];
        }
        
        [keyClassMap setObject:typeName forKey:key];
    }
    
    NSString *end = @"@end";
    [_hCode addLine:line__(end, 0)];
    [_hCode addLine:line__(@"", 0)];
    
    //.m
    begin = [NSString stringWithFormat:@"@implementation %@", clsName];
    [_mCode addLine:line__(begin, 0)];
    [_mCode addLine:line__(@"", 0)];
    
    //add keymaps
    [_mCode addLine:line__(@"+ (NSDictionary *)JSONKeyPathsByPropertyKey {", 0)];
    [_mCode addLine:line__(@"return @{", 1)];
    
    NSInteger count = allKeys.count;
    NSString *keyNameMap = nil;
    for (NSUInteger i = 0; i < count; ++i) {
        if (i < count - 1) {
            keyNameMap = [NSString stringWithFormat:@"@\"%@\":@\"%@\",",keyMap[allKeys[i]],allKeys[i]];
        }else {
            keyNameMap = [NSString stringWithFormat:@"@\"%@\":@\"%@\"",keyMap[allKeys[i]],allKeys[i]];
        }
        [_mCode addLine:line__(keyNameMap, 2)];
    }
    
    [_mCode addLine:line__(@"};", 1)];
    [_mCode addLine:line__(@"}", 0)];
    
    //add init
    [_mCode addLine:line__(@"- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error {", 0)];
    [_mCode addLine:line__(@"self = [super initWithDictionary:dictionaryValue error:error];", 0)];
    [_mCode addLine:line__(@"if (self) {", 1)];
    [_mCode addLine:line__(@" ", 1)];
    [_mCode addLine:line__(@"}", 1)];
    [_mCode addLine:line__(@"return self;", 1)];
    [_mCode addLine:line__(@"}", 0)];
    
    //add property transformer
    
    for (NSString *key in allKeys) {
        [self addTransformer:_mCode type:keyClassMap[key] propertyName:keyMap[key] value:json[key]];
    }
    end = @"@end";
    [_mCode addLine:line__(end, 0)];
    [_mCode addLine:line__(@"", 0)];
}

- (NSArray<NSString *> *)sortASC:(NSArray *)keyArray {
    return [keyArray sortedArrayUsingComparator:^NSComparisonResult(NSString *_Nonnull obj1, NSString *_Nonnull obj2) {
        if (obj1.length < obj2.length) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
}

- (NSArray<NSString *> *)sortDESC:(NSArray *)keyArray {
    return [keyArray sortedArrayUsingComparator:^NSComparisonResult(NSString *_Nonnull obj1, NSString *_Nonnull obj2) {
        if (obj1.length < obj2.length) {
            return NSOrderedDescending;
        }
        return NSOrderedAscending;
    }];
}

- (void)addTransformer:(MXCode *)code type:(NSString *)typeName propertyName:(NSString *)pName value:(NSObject *)value {
    NSArray *typeSet = @[kType_CGFloat, kType_NSInteger, kType_BOOL, kType_String, kType_id];
    
    NSString *str = nil;
    if ([typeSet containsObject:typeName] ||
        ([typeName isEqualToString:kType_NSArray] && [self baseArray:value])) {//base type
        
        str = [NSString stringWithFormat:@"//Type:%@", typeName];
        [code addLine:line__(str, 0)];
        
        str = [NSString stringWithFormat:@"+ (NSValueTransformer *)%@JSONTransformer {", pName];
        [code addLine:line__(str, 0)];
        
        [code addLine:line__(@"    return [MTLValueTransformer transformerUsingForwardBlock:^id(id rawValue,BOOL *success, NSError *__autoreleasing *error){", 0)];
        
        [code addLine:line__(@"                return rawValue;", 0)];
        
        [code addLine:line__(@"    }];", 0)];
        
        [code addLine:line__(@"}", 0)];
    }else {//json obj
        if ([value isKindOfClass:[NSArray class]]) {
            str = [NSString stringWithFormat:@"+ (NSValueTransformer *)%@JSONTransformer {", pName];
            [code addLine:line__(str, 0)];
            
            str = [NSString stringWithFormat:@"return [MTLJSONAdapter arrayTransformerWithModelClass:%@.class];", typeName];
            [code addLine:line__(str, 1)];
            [code addLine:line__(@"}", 0)];
        }else {
            str = [NSString stringWithFormat:@"+ (NSValueTransformer *)%@JSONTransformer {", pName];
            [code addLine:line__(str, 0)];
            
            str = [NSString stringWithFormat:@"return [MTLJSONAdapter dictionaryTransformerWithModelClass:%@.class];", typeName];
            [code addLine:line__(str, 1)];
            [code addLine:line__(@"}", 0)];
        }
    }
    
    [code addLine:line__(@" ", 0)];
}

- (BOOL)baseArray:(NSObject *)obj {
    if (obj && [obj isKindOfClass:[NSArray class]]) {
        NSArray *arr = (NSArray *)obj;
        if (arr.count > 0) {
            NSObject *item = arr.firstObject;
            if ([item isKindOfClass:[NSDictionary class]]) {
                return NO;
            }else {
                return YES;
            }
        }else {
            return YES;
        }
    }else {
        return YES;
    }
}

- (NSDictionary *)jsonObject:(NSObject *)rawValue {
    if (rawValue && [rawValue isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)rawValue;
    }
    
    if (rawValue && [rawValue isKindOfClass:[NSArray class]]) {
        NSArray *arr = (NSArray *)rawValue;
        if (arr.count > 0) {
            NSObject *obj = arr.firstObject;
            if ([obj isKindOfClass:[NSDictionary class]]) {
                return (NSDictionary *)obj;
            }
        }
    }
    return nil;
}

- (NSString *)propertyOf:(NSString *)className value:(NSObject *)value propertyName:(NSString *)name {
    
    NSString *formatString = nil;
    if ([className isEqualToString:kType_NSInteger]) {
        formatString = @"@property (nonatomic, assign) %@ %@;";
    }else if ([className isEqualToString:kType_CGFloat]) {
        formatString = @"@property (nonatomic, assign) %@ %@;";
    }else if ([className isEqualToString:kType_String]) {
        formatString = @"@property (nonatomic, copy) %@ *%@;";
    }else if ([className isEqualToString:kType_BOOL]) {
        formatString = @"@property (nonatomic, assign) %@ %@;";
    }else if ([className isEqualToString:kType_NSArray]) {
        if (value) {
            NSArray *arr = (NSArray *)value;
            if (arr.count > 0) {
                NSObject *item = arr.firstObject;
                if ([item isKindOfClass:[NSString class]]) {
                    formatString = @"@property (nonatomic, strong) %@<NSString *> *%@;";
                }else {
                    formatString = @"@property (nonatomic, strong) %@ *%@;";
                }
            }else {
                formatString = @"@property (nonatomic, strong) %@ *%@;";
            }
        }else {
            formatString = @"@property (nonatomic, strong) %@ *%@;";
        }
        
    }else if ([className isEqualToString:kType_id]) {
        formatString = @"@property (nonatomic, strong) %@ %@;";
    }else {
        if ([value isKindOfClass:[NSArray class]]) {
            formatString = @"@property (nonatomic, strong) NSArray<%@ *> *%@;";
        }else {
            formatString = @"@property (nonatomic, strong) %@ *%@;";
        }
    }
    return [NSString stringWithFormat:formatString, className, name];
}

- (NSString *)checkKey:(NSString *)key {
    NSArray *ocKeyWords = @[@"id",@"__VERSION__",@"default",@"description"];
    NSString *keyNew = [key stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    if ([ocKeyWords containsObject:keyNew]) {
        return [NSString stringWithFormat:@"%@_", keyNew];
    }else {
        return keyNew;
    }
}
    
- (NSString *)classNameOfValue:(id)aValue
                           key:(NSString *)key
                     className:(NSString *) className{
    
    NSString *typeName = @"";
    if ([aValue respondsToSelector:@selector(objCType)]) {//标量 整形、浮点、bool
        if (strcmp([aValue objCType], @encode(long long)) == 0) {//整形
            typeName = kType_NSInteger;
        }else if (strcmp([aValue objCType], @encode(double)) == 0) {//浮点
            typeName = kType_CGFloat;
        }else if (strcmp([aValue objCType], @encode(char)) == 0) {//bool
            typeName = kType_BOOL;
        }
    }else{
        if ([aValue isKindOfClass:[NSString class]]) {//字符串
            typeName = kType_String;
        }else if ([aValue isKindOfClass:[NSArray class]]){//数组
            NSObject *obj = [(NSArray *)aValue firstObject];
            if ([obj isKindOfClass:[NSDictionary class]]) {
                typeName = [NSString stringWithFormat:@"%@_%@",className, key];
            }else {
                typeName = kType_NSArray;
            }
        }else if ([aValue isKindOfClass:[NSDictionary class]]){//字典
            typeName = [NSString stringWithFormat:@"%@_%@",className, key];
        }else{//未知类型
            typeName = kType_id;
        }
    }
    return typeName;
}

+ (void)createHeaderFileOfClass:(NSString *)className of:(NSDictionary *)jsonDic storeIn:(NSMutableArray *)bags{
    if (!jsonDic) {
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
    if (!jsonDic) {
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
            
            NSArray *array = (NSArray *)value;
            if (array.count > 0) {
                id item = array.firstObject;
                if ([NSMantleClassCreater isBaseTypeOrString:item]) {
                    [MFile appendString:[NSString stringWithFormat:kBaseValueTransformerFunc,key]];
                }else {
                    [MFile appendString:[NSString stringWithFormat:kArrayValueTransformerFunc,key,[NSString stringWithFormat:@"%@_%@",className,key]]];
                }
            }else {
                [MFile appendString:[NSString stringWithFormat:kBaseValueTransformerFunc,key]];
            }
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
            NSArray *array = (NSArray *)aValue;
            if (array.count > 0) {
                id item = array.firstObject;
                if ([NSMantleClassCreater isBaseTypeOrString:item]) {
                    typeName = kType_NSArray;
                }else {
                    typeName = kType_NSArray;
                }
            }else {
                typeName = kType_NSArray;
            }
            
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

+ (BOOL)isBaseTypeOrString:(id)value {
    if ([value respondsToSelector:@selector(objCType)]) {
        return YES;
    }else {
        if ([value isKindOfClass:[NSString class]]) {
            return YES;
        }else {
            return NO;
        }
    }
}

@end
