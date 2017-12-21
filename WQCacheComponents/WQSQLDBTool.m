//
//  WQSQLDBTableTool.m
//  WQCacheDemo
//
//  Created by WangQiang on 2017/6/3.
//  Copyright © 2017年 WQCacheKit. All rights reserved.
// 数据库表辅助工具

#import "WQSQLDBTool.h"
#import <objc/runtime.h>
#import <FMDB/FMDB.h>

@implementation WQSQLDBTool

//TODO: 根据模型生成建表的SQL语句
+(NSString *)createTableSQL:(WQDBModelClass)modelCls{
    // 1. 创建表格的sql语句给拼接出来
    // create table if not exists 表名(字段1 字段1类型, 字段2 字段2类型 (约束),...., primary key(字段))
    // 1.1 获取表格名称
    NSString *tableName = [modelCls t_tableName];
    NSString *primaryKey = [modelCls primaryKey];
    NSDictionary *dbTypes = objcTypeMapToDBTypes();
    NSMutableString *createTableSql = [NSMutableString stringWithFormat:@"create table if not exists %@ ",tableName];
  //创建表(字段不排序) 获取一个模型里面所有的字段, 以及类型
    [createTableSql appendString:@"("];
    [[self classDBPropertiesTypes:modelCls] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        NSAssert(dbTypes[obj], @"请创建一个常规的数据库支持的类型");
        [createTableSql appendFormat:@"%@ %@,",key,dbTypes[obj]];
    }];
    [createTableSql appendFormat:@"primary key(%@)",primaryKey];
    [createTableSql appendString:@")"];
 
    return createTableSql;
}
+(NSArray *)parseModels:(WQDBModelClass)modelCls FMResultSet:(FMResultSet *)rs{
    NSDictionary *dbTypes = objcTypeMapToDBTypes();
    NSDictionary *properties = [self classDBPropertiesTypes:modelCls];
    NSMutableArray *models = [NSMutableArray array];
    while (rs.next) {
        WQDBModelClass model = [[modelCls alloc] init];
        [properties enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            id value ;
            NSString *type = dbTypes[obj];
            
            if([type isEqualToString:@"text"]){
                value = [rs stringForColumn:key];
            }else if ([type isEqualToString:@"blob"]){
                NSData *data = [rs dataForColumn:key];
                if(![obj isEqualToString:@"NSData"]){
                    value = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                }else{
                    value = data;
                }
            }else if ([type isEqualToString:@"integer"]){
                if ([obj isEqualToString:@"NSDate"]) {
                    value = [NSDate dateWithTimeIntervalSince1970:[rs doubleForColumn:key]];
                }else{
                    value = @([rs intForColumn:key]);
                }
            }else{//real
                value = @([rs doubleForColumn:key]);
            }
 
            [model setValue:value forKeyPath:key];
        }];
        [models addObject:model];
    }
    return models;
}
+ (NSString *)saveModelsSql:(NSArray *)models{
    if (![models isKindOfClass:[NSArray class]] ||models.count <= 0) return @"";
    WQDBModelClass modelCls = [[models firstObject] class];
     NSDictionary *properties = [self classDBPropertiesTypes:modelCls];
    NSAssert(properties.count > 0, @"对象必须要有属性");
    
//insert into table () values (),(),(),() 不使用事务也很快
    NSString *tableName = [modelCls t_tableName];
    
    NSArray *propertyNames = properties.allKeys;
    NSMutableString *sqls = [NSMutableString stringWithFormat:@"insert into %@ ",tableName];
    
     NSInteger indexMax = propertyNames.count - 1 ;
    
    [sqls appendString:@"( "];
    [propertyNames enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == indexMax) {
            [sqls appendFormat:@"%@ ",obj];
        }else{
            [sqls appendFormat:@"%@, ",obj];
        }
    }];
    [sqls appendString:@") "];
    
    [sqls appendString:@"values "];
    
    for (id model in models) {
        [sqls appendString:@"( "];
        [propertyNames enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
          //需要判断
            id value = [model valueForKey:obj];
            if ([value isKindOfClass:[NSString class]]) {
                [sqls appendFormat:@"'%@'",value];
            }else if([value isKindOfClass:[NSDate class]]){
                NSDate *date = (NSDate *)value;
                [sqls appendFormat:@"%lf",date.timeIntervalSince1970];
            }else{
                [sqls appendFormat:@"%@",value];
            }
            if (idx != indexMax) {//最后一个
                [sqls appendString:@", "];
            }
        }];
        [sqls appendString:@"),"];
    }
    [sqls deleteCharactersInRange:NSMakeRange(sqls.length - 1, 1)];
    return sqls;
}
+(NSArray<NSString *> *)saveModelSqls:(NSArray *)models{
    if (![models isKindOfClass:[NSArray class]] ||models.count <= 0) return [NSArray array];
    WQDBModelClass modelCls = [[models firstObject] class];
    NSDictionary *properties = [self classDBPropertiesTypes:modelCls];
    NSAssert(properties.count > 0, @"对象必须要有属性");
 
    NSString *tableName = [modelCls t_tableName];
    
    NSArray *propertyNames = properties.allKeys;
    NSMutableString *preSql = [NSMutableString stringWithFormat:@"insert into %@ ",tableName];

    NSInteger indexMax = propertyNames.count - 1 ;
    
    [preSql appendString:@"( "];
    [propertyNames enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == indexMax) {
            [preSql appendFormat:@"%@ ",obj];
        }else{
            [preSql appendFormat:@"%@, ",obj];
        }
    }];
    [preSql appendString:@") "];
    
    [preSql appendString:@"values "];
    
    NSMutableArray *sqls = [NSMutableArray array];
    
    
    for (id model in models) {
        NSMutableString *sql = [NSMutableString stringWithFormat:@"%@ ( ",preSql];
        [propertyNames enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            //需要判断
            id value = [model valueForKey:obj];
            if ([value isKindOfClass:[NSString class]]) {
                [sql appendFormat:@"'%@'",value];
            }else if([value isKindOfClass:[NSDate class]]){
                NSDate *date = (NSDate *)value;
                [sql appendFormat:@"%lf",date.timeIntervalSince1970];
            }else{
                [sql appendFormat:@"%@",value];
            }
            if (idx != indexMax) {//最后一个
                [sql appendString:@", "];
            }
        }];
        [sql appendString:@");"];
        [sqls addObject:sql];
    }
    return sqls;
}

+(NSString *)updateModel:(id)model updateKeys:(NSArray *)keys{
    WQDBModelClass modelCls = [model class];
    NSAssert([modelCls respondsToSelector:@selector(primaryKey)], @"模型必须实现主键方法");
 
    NSString *primaryKey = [modelCls primaryKey];
    NSMutableString *updateSql = [NSMutableString stringWithFormat:@"UPDATE %@ SET ",[modelCls t_tableName]];
    NSInteger indexMax = keys.count - 1;
    [keys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id value = [model valueForKey:obj];
        if ([value isKindOfClass:[NSString class]]) {
            [updateSql appendFormat:@"%@ = '%@' ",obj,value];
        }else{
              [updateSql appendFormat:@"%@ = %@ ",obj,value];
        }
        if (idx != indexMax) {
            [updateSql appendString:@", "];
        }
    }];
    id primaryValue = [model valueForKey:primaryKey];
    if ([primaryValue isKindOfClass:[NSString class]]) {
        [updateSql appendFormat:@"WHERE %@ = '%@' ",primaryKey,primaryValue];
    }else{
        [updateSql appendFormat:@"WHERE %@ = %@ ",primaryKey,primaryValue];
    }
    [updateSql appendString:@";"];
    return updateSql;
    
}
//MARK: - -- 获取对象的数据库字段类型
+(NSDictionary<NSString *, NSString *> *)classMapToDB:(WQDBModelClass)modelCls{
    return [self classPropertiesMapToDB:[self classDBPropertiesTypes:modelCls]];
}

#pragma mark - 私有的方法

//MARK: - -- 根据属性字典映射出对应数据库类型字段
/**
 @param typeDic 类型的属性名跟属性类型
 @return 类型的属性名跟属性对应的数据库类型
 */
+(NSDictionary<NSString *,NSString *> *)classPropertiesMapToDB:(NSDictionary *)typeDic{
    NSMutableDictionary *clsMapDBTypes = [NSMutableDictionary dictionary];
    NSDictionary *dbTypes = objcTypeMapToDBTypes();
    [typeDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {
        NSAssert(dbTypes[obj], @"请创建一个常规的数据库支持的类型");
        clsMapDBTypes[key] = dbTypes[obj];
    }];
    return clsMapDBTypes;
}

//TODO: 将属性名称进行排序
+ (NSArray <NSString *>*)sortedClassPropertiesName:(NSArray *)names{
    NSArray *keys  = [NSArray array];
    keys = [names sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    return keys;
}



/**
 //MARK: - --获取一个对象需要存储到数据库的所有属性以及对应的类型
 */
+(NSDictionary<NSString *, NSString *> *)classDBPropertiesTypes:(WQDBModelClass)modelCls{
    // 获取这个类, 里面, 所有的成员变量以及类型
    NSMutableDictionary *nameTypeDic = [NSMutableDictionary dictionary];
    NSArray *ignoreNames = nil;
    if ([modelCls respondsToSelector:@selector(ignoreColumnNames)]) {
        ignoreNames = [modelCls ignoreColumnNames];
    }
    do {
        unsigned int outCount = 0;
        Ivar *varList = class_copyIvarList(modelCls, &outCount);
        for (int i = 0; i < outCount; i++) {
            Ivar ivar = varList[i];
            // 1. 获取成员变量名称
            NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
           // 判断当前属性是否需要存储
            if(ignoreNames && [ignoreNames containsObject:ivarName]) {
                continue;
            }
            // 2. 获取成员变量类型
            NSString *type = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
            //  剔除字符串中首尾的一些字符
            type = [type stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"@\""]];
            [nameTypeDic setValue:type forKey:ivarName];
        }
        free(varList);
        modelCls = [modelCls superclass];
    } while (modelCls != [NSObject class]);
    
    return nameTypeDic;
}

///**
// 获取oc类型对应的数据库类型
//
// @param objcType oc类型
// @return 数据库类型
// */
//NSString *objcToDBType(NSString *objcType){
//    NSString *dbType = objcTypeMapToDBTypes()[objcType];
//    NSAssert(dbType, @"请创建一个常规的数据库支持的类型");
//    return dbType;
//}

//TODO: 运行时的字段类型到sql字段类型的映射表
NSDictionary<NSString *, NSString *> * objcTypeMapToDBTypes(){
    static NSDictionary *ocToDBTypes_;
    
    if(!ocToDBTypes_){
        ocToDBTypes_ = @{
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
                         @"NSString": @"text",
                         @"NSMutableString":@"text",
                         @"NSDate":@"real"
                         };
    }
    return ocToDBTypes_;
 
}

//MARK: =========== SQL功能语句 ===========
//TODO: 数据库表信息查询处理=====================
/**
// 获取查询结果里面的数据库字段
NSString *createTableSql = dic[@"sql"];
if (createTableSql.length == 0) {
    return nil;
}
createTableSql = [createTableSql stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
//因为OC字典里面有自带的一些格式化美化符号 所以需要去掉
createTableSql = [createTableSql stringByReplacingOccurrencesOfString:@"\"" withString:@""];
createTableSql = [createTableSql stringByReplacingOccurrencesOfString:@"\n" withString:@""];
createTableSql = [createTableSql stringByReplacingOccurrencesOfString:@"\t" withString:@""];

// CREATE TABLE XMGStu((stuNum))

// 1. age integer,stuNum integer,score real,name text, primary key
//    CREATE TABLE "XMGStu" ( \n
//                           "age2" integer,
//                           "stuNum" integer,
//                           "score" real,
//                           "name" text,
//                           PRIMARY KEY("stuNum")
//                           )


NSString *nameTypeStr = [createTableSql componentsSeparatedByString:@"("][1];

// age integer
// stuNum integer
// score real
// name text
// primary key
NSArray *nameTypeArray = [nameTypeStr componentsSeparatedByString:@","];

NSMutableArray *names = [NSMutableArray array];
for (NSString *nameType in nameTypeArray) {
    
    if ([[nameType lowercaseString] containsString:@"primary"]) {
        continue;
    }
    NSString *nameType2 = [nameType stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    
    
    // age integer
    NSString *name = [nameType2 componentsSeparatedByString:@" "].firstObject;
    
    [names addObject:name];
    
}*/
//TODO: 数据库表信息查询处理END=====================

+(NSString *)QueryTableInfoSQL:(WQDBModelClass)modelCls{
    /** 查询数据库表的所有字段的名称 */
    //sqlite_master 每个数据库都默认都有的 (查询数据库中的表)
    //mysql安装成功后可以看到已经存在mysql、information_schema和test这个几个数据库，information_schema库中有一个名为COLUMNS的表，这个表中记录了数据库中所有表的字段信息。知道这个表后，获取任意表的字段就只需要一条select语句即可
    //    select COLUMN_NAME from information_schema.COLUMNS where table_name = 'your_table_name';
    //字典里面的sql字段 即为查询到字段名跟类型 如果字典为空就说明没有该表
    return [NSString stringWithFormat:@"select sql from sqlite_master where type = 'table' and name = '%@'", [modelCls t_tableName]];
}

+ (NSArray *)MoveTableSQL:(WQDBModelClass)modelCls dbProperties:(NSDictionary *)dbNames{
    // 1. 创建一个拥有正确结构的临时表
    // 1.1 获取表格名称
     NSString *tableName = [modelCls t_tableName];
    NSString *tmpTableName = [NSString stringWithFormat:@"temp_%@",tableName];
    
    if (![modelCls respondsToSelector:@selector(primaryKey)]) {
        NSAssert(NO, @"如果想要操作这个模型, 必须要实现+ (NSString *)primaryKey;这个方法, 来告诉我主键信息");
    }
    NSMutableArray *execSqls = [NSMutableArray array];
    NSString *primaryKey = [modelCls primaryKey];
    NSString *dropTmpTableSql = [NSString stringWithFormat:@"drop table if exists %@;", tmpTableName];
    [execSqls addObject:dropTmpTableSql];
    NSString *createTableSql = [self createTableSQL:modelCls];
    [execSqls addObject:createTableSql];
    
    // 2. 根据主键, 先插入条数
    NSString *insertPrimaryKeyData = [NSString stringWithFormat:@"insert into %@(%@) select %@ from %@;", tmpTableName, primaryKey, primaryKey, tableName];
    [execSqls addObject:insertPrimaryKeyData];
    
    // 3. 根据主键, 把所有的数据更新到新表里面
    NSArray *oldNames = [self sortedClassPropertiesName:dbNames.allKeys];
    NSArray *newNames = [self sortedClassPropertiesName:[self classDBPropertiesTypes:modelCls].allKeys];
    
    // 4. 获取更名字典
    NSDictionary *newNameToOldNameDic = [NSDictionary dictionary];
    //  @{@"age": @"age2"};
    if ([modelCls respondsToSelector:@selector(newNameToOldNameDic)]) {
        newNameToOldNameDic = [modelCls newNameToOldNameDic];
    }
    
    for (NSString *newName in newNames) {
        //每次更新一列(一个字段的值)
        NSString *oldName = newName;
        // 找映射的旧的字段名称
        if (newNameToOldNameDic[newName] ) {
            oldName = newNameToOldNameDic[newName];
        }
        
        if ((![oldNames containsObject:newName] && ![oldNames containsObject:oldName]) || [newName isEqualToString:primaryKey]) {
            continue;
        }
        // 如果老表包含了新的, 应该从老表更新到临时表格里面
        
        //        xmgstu_tmp  age
        // update 临时表 set 新字段名称 = (select 旧字段名 from 旧表 where 临时表.主键 = 旧表.主键)
        NSString *updateSql = [NSString stringWithFormat:@"update %@ set %@ = (select %@ from %@ where %@.%@ = %@.%@);", tmpTableName, newName, oldName, tableName, tmpTableName, primaryKey, tableName, primaryKey];
        [execSqls addObject:updateSql];
    }
    
    //删除当前表
    [execSqls addObject:[NSString stringWithFormat:@"drop table if exists %@;", tableName]];
    //将临时表名改为正式表名
    [execSqls addObject:[NSString stringWithFormat:@"alter table %@ rename to %@;", tmpTableName, tableName]];
    return execSqls;
}

+(BOOL)RequiredTableUpdate:(WQDBModelClass)modelCls dbProperties:(NSDictionary *)dbNames{
    NSArray *oldNames = [self sortedClassPropertiesName:dbNames.allKeys];
    NSArray *currentNames = [self sortedClassPropertiesName:[self classDBPropertiesTypes:modelCls].allKeys];
    return [oldNames isEqualToArray:currentNames];
}
@end
