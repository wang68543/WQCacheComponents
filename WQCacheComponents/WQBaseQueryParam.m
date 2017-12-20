//
//  WQBaseQueryParam.m
//  WQCacheDemo
//
//  Created by WangQiang on 2017/5/27.
//  Copyright © 2017年 WQCacheKit. All rights reserved.
//

#import "WQBaseQueryParam.h"
#import "WQSQLDBTool.h"
#import <objc/runtime.h>
#import <FMDB/FMDB.h>
@implementation WQQueryCondition
+ (instancetype)conditionColumnName:(NSString *)columnName relationship:(WQRelationType)relation toValue:(NSString *)value{
    return [[self alloc] initColumnName:columnName relationship:relation toValue:value];
}
- (instancetype)initColumnName:(NSString *)columnName relationship:(WQRelationType)relation toValue:(NSString *)value{
    if(self = [super init]){
        self.columnName = columnName;
        self.relationType = relation;
        self.value  = value;
    }
    return self;
}
- (BOOL)isEmpty{
    return self.columnName.length <= 0 || self.value.length <= 0;
}


-(NSString *)SQLFormat{
    if(!self.isEmpty){
        NSString *sql  = nil;
        NSString *relation = [WQQueryCondition columnToValueRelationWithType:self.relationType];
        switch (self.valueType) {
            case WQConditionValueTypeFloat:
                sql = [NSString stringWithFormat:@"%@ %@ %f ",self.columnName,relation,[self.value floatValue]];
                break;
            case WQConditionValueTypeInteger:
                sql = [NSString stringWithFormat:@"%@ %@ %ld ",self.columnName,relation,[self.value integerValue]];
                break;
            case WQConditionValueTypeString:
            default:
                sql = [NSString stringWithFormat:@"%@ %@ '%@' ",self.columnName,relation,self.value];
                break;
        }
        return sql;
    }else{
        return @"";
    }
   
}
+(NSString *)columnToValueRelationWithType:(WQRelationType)relationType{
    NSString *relationStr = nil;
    switch (relationType) {
        case  WQRelationTypeMore: // >
            relationStr = @">";
            break;
        case WQRelationTypeLess :// <
            relationStr = @"<";
            break;
        case WQRelationTypeEqual :// =
            relationStr = @"=";
            break;
        case WQRelationTypeEqualMore: // >=
            relationStr = @">=";
            break;
        case WQRelationTypeEqualLess:
            relationStr = @"<=";
            break;
        case WQRelationTypeIsNot:
            relationStr = @"!=";
            break;
            
    }
    return relationStr;
}
@end

@implementation WQBaseQueryParam
+(NSString *)db_cacheDirectory{
    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *cachePath = [cacheDirectory stringByAppendingPathComponent:@"WQSQLCache"];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:cachePath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath     withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return cachePath;
}
+(NSString *)db_name{
    return [NSString stringWithFormat:@"%@.sqlite",NSStringFromClass([self class])];
}

-(Class)modelClass{
    NSAssert(NO, @"此方法必须子类实现");
    return nil;
}
-(NSString *)t_tableName{
    NSAssert(NO, @"此方法必须子类实现");
    return nil;
}
//TODO: -- 查询
- (NSString *)queryParamFormatSQLString{
    return [NSString stringWithFormat:@"SELECT * FROM %@ %@;",[self t_tableName],[self conditionSQLString]];
}

//TODO: -- 删除
- (NSString *)deleteParamFormatSQLString{
    return [NSString stringWithFormat:@"DELETE FROM %@ %@;",[self t_tableName],[self conditionSQLString]];
}

//TODO: -- 更新
-(NSString *)updateSQL:(id)model updateKeys:(NSArray *)keys{
    NSMutableString *updateSql = [NSMutableString stringWithFormat:@"UPDATE %@ SET ",[self t_tableName]];
    NSInteger keysCount = keys.count;
    [keys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //网址里面包含冒号 需要用引号包含起来
        if ([obj isEqualToString:@"content"]) {
            [updateSql appendFormat:@"%@= '%@' ",obj,[model valueForKey:obj]];
        }else{
            [updateSql appendFormat:@"%@= %@ ",obj,[model valueForKey:obj]];
        }
        
        if(idx < keysCount - 1){
            [updateSql appendFormat:@", "];
        }
    }];
    [updateSql appendString:[self conditionSQLString]];
    [updateSql appendString:@";"];
    return [updateSql copy];
}
-(NSString *)formatExtraConditions{
    return @"";
}

-(NSString *)conditionSQLString{
    NSMutableString *SQL = [[NSMutableString alloc] init];
    [SQL appendString:self.sameLimit.SQLFormat];
    //TODO: 子类实现
    NSString *subFormatExtra = [self formatExtraConditions];
    if([subFormatExtra stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 0){
        if(SQL.length > 0 ){
            [SQL appendString:@"AND "];
        }
        [SQL appendFormat:@"%@ ",subFormatExtra];
    }
    
    if(SQL.length > 0){
        [SQL insertString:@"WHERE " atIndex:0];
    }
    
    //排序
    if(self.orderByKey.length > 0 && self.orderType != kOrderNone){
        [SQL appendFormat:@"ORDER BY %@ ",self.orderByKey];
        if(self.orderType == kOrderDescending){
            [SQL appendString:@"DESC "];
        }else{
            [SQL appendString:@"ASC "];
        }
    }
    //分页
    if (self.limit > 0) {
        [SQL appendFormat:@"LIMIT %ld ",self.limit];
    }
    if (self.offset > 0) {
        [SQL appendFormat:@"OFFSET %ld ",self.offset];
    }
    //限制条件
//    if(self.limit > 0 && self.offset > 0){
//        [SQL appendFormat:@"limit %ld, %ld ",self.offset , self.limit];
//    }else{
//         [SQL appendFormat:@"limit %ld ",self.limit];
//    }

    return SQL;
}
////MARK: 私有方法 将自身转为SQL语句
//- (NSString *)formatWhereSQLString{
//    NSMutableString *SQL = [[NSMutableString alloc] init];
// 
//    //查询条件
//    NSString *sameSQL = self.sameLimit.SQLFormat;
//    NSMutableString *extraSQL ;
//    if(sameSQL && sameSQL.length > 0){
//        extraSQL = [NSMutableString stringWithString:sameSQL];
//    }else{
//        extraSQL = [NSMutableString string];
//    }
//    
//    //TODO: 子类实现
//    NSString *subFormatExtra = [self formatExtraConditions];
//    if(subFormatExtra.length > 0){
//        if(extraSQL.length > 0 ){
//            [extraSQL appendString:@"AND "];
//        }
//        [extraSQL appendFormat:@"%@ ",subFormatExtra];
//    }
//    
//    if(extraSQL.length > 0){
//        [SQL appendFormat:@"where %@ ",extraSQL];
//    }
//    
//    //排序
//    if(self.orderByKey.length > 0){
//        if(self.orderType != kOrderNone){
//            [SQL appendFormat:@"ORDER BY %@ ",self.orderByKey];
//            if(self.orderType == kOrderDescending){
//                [SQL appendString:@"DESC "];
//            }else{
//                [SQL appendString:@"ASC "];
//            }
//        }
//    }
//    
//    //限制条件
//    if(self.limit > 0){
//        if(self.offset > 0){
//            [SQL appendFormat:@"limit %ld, %ld ",self.offset , self.limit];
//        }else{
//          [SQL appendFormat:@"limit %ld ",self.limit];
//        }
//    }
//    return SQL;
//}
@end
