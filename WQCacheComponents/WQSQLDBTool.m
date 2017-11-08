//
//  WQSQLDBTableTool.m
//  WQCacheDemo
//
//  Created by WangQiang on 2017/6/3.
//  Copyright © 2017年 WQCacheKit. All rights reserved.
// 数据库表辅助工具

#import "WQSQLDBTool.h"
#import <objc/runtime.h>

@implementation WQSQLDBTool
//TODO: 解析本地数据库查询数据的模型(根据请求参数进行)
+ (NSArray *)parseModels:(Class<WQSQLMoelProtocol>)modelClass FMResultSet:(FMResultSet *)rs{
    //数据库中字段名和类型
    NSDictionary *dbTypes = [self ocTypeToSqliteTypeDic];
    //模型的属性名和类型
    NSDictionary *modelTypes = [self classIvarNameTypeDic:modelClass];
    NSMutableArray *models = [NSMutableArray array];
    while (rs.next) {
        NSObject<WQSQLMoelProtocol> *model = [[modelClass alloc] init];
        for (NSString *key in modelTypes.allKeys) {
            NSString *type = dbTypes[modelTypes[key]];
            id value ;
            if([type isEqualToString:@"text"]){
                value = [rs stringForColumn:key];
            }else if ([type isEqualToString:@"blob"]){
                NSData *data = [rs dataForColumn:key];
                if(![modelTypes[key] isEqualToString:@"NSData"]){
                    value = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                }else{
                    value = data;
                }
            }else if ([type isEqualToString:@"integer"]){
                value = @([rs intForColumn:key]);
            }else{
                value = @([rs doubleForColumn:key]);
            }
       
            [model setValue:value forKeyPath:key];
        }
        [models addObject:model];
    };
    return models;
}
+(NSArray *)saveModelsSQL:(NSArray *)models{
    return [self saveModelsSQL:models tableName:nil];
}
/**
 批量生成保存SQL语句
 */
+ (NSArray *)saveModelsSQL:(NSArray *)models tableName:(NSString *)t_table{
     if(![models isKindOfClass:[NSArray class]] || models.count <= 0) return [NSArray array];
    
    NSString *tableName = t_table;
    if(t_table.length <= 0){
        tableName =  [self t_tableName:[models.firstObject class]];
    }
    // 获取字段名称字典
    NSArray *columnNames = [self classIvarNameTypeDic:[models.firstObject class]].allKeys;
    
    NSMutableArray *saveModelSqls = [NSMutableArray array];
    for (id model  in models) {
        [saveModelSqls addObject:[self saveModelSQL:model tableName:tableName columnNames:columnNames]];
    }
    return saveModelSqls;
}

+(NSString *)saveModelSQL:(id)model{
    return [self saveModelSQL:model tableName:nil];
}
/**
 保存模型到数据库
 @return 存储SQL语句
 */
+ (NSString *)saveModelSQL:(id)model tableName:(NSString *)t_table{
    return [self saveModelSQL:model tableName:[self t_tableName:[model class]] columnNames: [self classIvarNameTypeDic:[model class]].allKeys];
}


/**
 保存模型到数据库
 
 @param model 模型
 @param columnNames 数据中的字段名(即模型的属性名)
 @return 存储SQL语句
 */
+ (NSString *)saveModelSQL:(id)model tableName:(NSString *)tableName columnNames:(NSArray *)columnNames{
    NSMutableArray *values = [NSMutableArray array];
    for (NSString *columnName in columnNames) {
        id value = [model valueForKeyPath:columnName];
        if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
            // 在这里, 把字典或者数组, 处理成为二进制
            NSData *data = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingPrettyPrinted error:nil];
            value = data;
        }
        if(!value){
           [values addObject:@""];
        }else{
           [values addObject:value];
        }
       
    }
    
    return  [NSString stringWithFormat:@"insert into %@(%@) values('%@');", tableName, [columnNames componentsJoinedByString:@","], [values componentsJoinedByString:@"','"]];
}


//TODO: 获取表格名称
+ (NSString *)t_tableName:(Class)cls {
    if([cls respondsToSelector:@selector(t_tableName)]){
        return [cls t_tableName];
    }else{
       return [NSString stringWithFormat:@"t_%@",[NSStringFromClass(cls) lowercaseString]];
    }
    
}

//TODO: 获取临时表格名称 (猜测是用于数据库迁移)
+ (NSString *)tmpTableName:(Class)cls {
    return [[NSStringFromClass(cls) lowercaseString] stringByAppendingString:@"_tmp"];
}

//TODO: 根据模型生成建表的SQL语句
+ (NSString *)createTableSQL:(Class)cls{
    return [self createTableSQL:cls tableName:nil];
}
+(NSString *)createTableSQL:(Class)cls tableName:(NSString *)tableName{
    // 1. 创建表格的sql语句给拼接出来
    // 尽可能多的, 能够自己获取, 就自己获取, 实在判定不了用的意图的, 只能让用户来告诉我们
    // create table if not exists 表名(字段1 字段1类型, 字段2 字段2类型 (约束),...., primary key(字段))
    // 1.1 获取表格名称
    if(tableName.length <= 0){
         tableName = [self t_tableName:cls];
    }
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSLog(@"如果想要操作这个模型, 必须要实现+ (NSString *)primaryKey;这个方法, 来告诉我主键信息");
        return nil;
    }
    
    NSString *primaryKey = [cls primaryKey];
    
    // 1.2 获取一个模型里面所有的字段, 以及类型
    NSString *createTableSql = [NSString stringWithFormat:@"create table if not exists %@(%@, primary key(%@))", tableName, [self columnNamesAndTypesStr:cls], primaryKey];
    
    return createTableSql;
}
//TODO: 获取类的所有属性(用作数据库字段)和类型(不包含在ignoreIvarNames的属性),类型为运行时的类型(需转换)
+ (NSDictionary *)classIvarNameTypeDic:(Class)cls {
      //属性为key 类型为value
    
    // 获取这个类, 里面, 所有的成员变量以及类型
    
    
    NSMutableDictionary *nameTypeDic = [NSMutableDictionary dictionary];
    NSArray *ignoreNames = nil;
    if ([cls respondsToSelector:@selector(ignoreColumnNames)]) {
        ignoreNames = [cls ignoreColumnNames];
    }
     unsigned int outCount = 0;
    do {
       
        Ivar *varList = class_copyIvarList(cls, &outCount);
        for (int i = 0; i < outCount; i++) {
            Ivar ivar = varList[i];
            
            // 1. 获取成员变量名称
            NSString *ivarName = [NSString stringWithUTF8String: ivar_getName(ivar)];
            if ([ivarName hasPrefix:@"_"]) {
                ivarName = [ivarName substringFromIndex:1];
            }
            // 判断当前属性是否需要存储
            if([ignoreNames containsObject:ivarName]) {
                continue;
            }
            
            // 2. 获取成员变量类型
            NSString *type = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
            //stringByTrimmingCharactersInSet 剔除字符串中首尾的一些字符
            type = [type stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"@\""]];
            
            
            [nameTypeDic setValue:type forKey:ivarName];
            
        }
        free(varList);
        cls = [cls superclass];
        
    } while (cls != [NSObject class]);
   
    
   
    
    return nameTypeDic;
    
}
//TODO: 获取模型的所有属性(数据库字段名)和对应数据库中的类型(模型映射到数据库)
+ (NSDictionary *)classIvarNameSqliteTypeDic:(Class)cls {
      //属性为key 类型为value
    NSMutableDictionary *dic = [[self classIvarNameTypeDic:cls] mutableCopy];
    
    NSDictionary *typeDic = [self ocTypeToSqliteTypeDic];
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {
        dic[key] = typeDic[obj];
    }];
    
    return dic;
    
}


//TODO: 字段名称和sql类型, 拼接的用户创建表格的字符串
 //字符串 如: name text,age integer,score real
+ (NSString *)columnNamesAndTypesStr:(Class)cls {
    
    NSDictionary *nameTypeDic = [self classIvarNameSqliteTypeDic:cls];
    NSMutableArray *result = [NSMutableArray array];
    [nameTypeDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {
        
        [result addObject:[NSString stringWithFormat:@"%@ %@", key, obj]];
    }];

    return [result componentsJoinedByString:@","];
    
}

//TODO: 排序后的类名对应的成员变量数组, 用于和表格字段进行验证是否需要更新
+ (NSArray *)allTableSortedIvarNames:(Class)cls {
    
    NSDictionary *dic = [self classIvarNameTypeDic:cls];
    NSArray *keys = dic.allKeys;
    keys = [keys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    return keys;
}


#pragma mark - 私有的方法
//TODO: 运行时的字段类型到sql字段类型的映射表
+ (NSDictionary *)ocTypeToSqliteTypeDic {
    return @{
             @"d": @"real", // double
             @"f": @"real", // float
             
             @"i": @"integer",  // int
             @"q": @"integer", // long
             @"Q": @"integer", // long long
             @"B": @"integer", // bool
             
             @"NSData": @"blob",
             //用二进制存储字典/数组类型
             @"NSDictionary": @"blob",
             @"NSMutableDictionary": @"blob",
             @"NSArray": @"blob",
             @"NSMutableArray": @"blob",
             @"NSNumber": @"real",
//             //用text类型是便于存储
//             @"NSDictionary": @"text",
//             @"NSMutableDictionary": @"text",
//             @"NSArray": @"text",
//             @"NSMutableArray": @"text",
             
             @"NSString": @"text"
             };
    
}

@end
