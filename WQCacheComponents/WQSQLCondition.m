//
//  WQSQLCondition.m
//  WQCacheDemo
//
//  Created by hejinyin on 2017/12/21.
//  Copyright © 2017年 WQCacheKit. All rights reserved.
//

#import "WQSQLCondition.h"
@interface WQSQLCondition()
@end

@implementation WQSQLCondition
+ (instancetype)conditionColumnName:(NSString *)columnName relationship:(WQRelationType)relation toValue:(id)value{
    return [[self alloc] initColumnName:columnName relationship:relation toValue:value];
}
- (instancetype)initColumnName:(NSString *)columnName relationship:(WQRelationType)relation toValue:(id)value{
    if(self = [super init]){
        self.columnName = columnName;
        self.relationType = relation;
        self.value  = value;
    }
    return self;
}
- (BOOL)isEmpty{
    return self.columnName.length <= 0 || !self.value;
}

-(NSString *)SQLFormat{
    if(self.isEmpty) return @"";
    NSMutableString *sql  = [NSMutableString string];
    //需要语句连接
    switch (self.connectBeforeType) {
        case WQConditionConactAND:
            [sql appendString:@"AND "];
            break;
        case WQConditionConactOR:
            [sql appendString:@"OR "];
            break;
        case WQConditionConactORDER_BY:
            [sql appendString:@"ORDER BY "];
            break;
        case WQConditionConactNone:
        default:
            break;
    }
    NSString *relation = [WQSQLCondition columnToValueRelationWithType:self.relationType];
    sql = [NSMutableString stringWithFormat:@"%@ %@ ",self.columnName,relation];
    switch (self.valueType) {
        case WQConditionValueTypeFloat:
            [sql appendFormat:@"%f ",[self.value floatValue]];
            break;
        case WQConditionValueTypeInteger:
            [sql appendFormat:@"%ld ",[self.value integerValue]];
            break;
        case WQConditionValueTypeOrderEnum:
        {
            WQOrderType orderType = (WQOrderType)[self.value integerValue];
            switch (orderType) {
                case kOrderAscending:
                    [sql appendString:@"ASC "];
                    break;
                case kOrderDescending:
                    [sql appendString:@"DESC "];
                    break;
                case kOrderNone:
                default:
                    sql = [NSMutableString string];
                    break;
            }
        }
            break;
        case WQConditionValueTypeString:
            [sql appendFormat:@"'%@' ",self.value];
            break;
        case WQConditionValueTypeDefault:
        default:
            [sql appendFormat:@"%@ ",self.value];
            break;
    }
    
    return [sql copy];
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
        case WQRelationTypeNone:
        default:
            relationStr = @"";
            break;
    }
    return relationStr;
}

+ (NSString *)SQLWithConditions:(NSArray<WQSQLCondition *> *)conditions{
    //排序 把排序条件放在最后
   NSArray *sortedConditions = [conditions sortedArrayUsingComparator:^NSComparisonResult(WQSQLCondition * _Nonnull obj1, WQSQLCondition *  _Nonnull obj2) {
        return obj1.relationType < obj2.relationType;
    }];
    NSMutableString *sql = [NSMutableString stringWithString:@"WHERE "];
    [sortedConditions enumerateObjectsUsingBlock:^(WQSQLCondition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [sql appendFormat:@"%@",obj.SQLFormat];
    }];
    return sql;
}
+(NSString *)QuerySQL:(Class<WQSQLMoelProtocol>)modelCls conditions:(NSArray<WQSQLCondition *> *)conditions{
    return [NSString stringWithFormat:@"SELECT * FROM %@ %@ ",[modelCls t_tableName], [self SQLWithConditions:conditions]];
}
+(NSString *)QuerySQL:(Class<WQSQLMoelProtocol>)modelCls conditions:(NSArray<WQSQLCondition *> *)conditions limit:(NSInteger)limit offset:(NSInteger)offset{
    NSMutableString *sql = [NSMutableString stringWithString:[self QuerySQL:modelCls conditions:conditions]];
    if (limit > 0) {
        [sql appendFormat:@"LIMIT %ld",limit];
    }
    if (offset > 0) {
        [sql appendFormat:@"OFFSET %ld",limit];
    }
    return sql;
}

+(NSString *)DeleteSQL:(Class<WQSQLMoelProtocol>)modelCls conditions:(NSArray<WQSQLCondition *> *)conditions{
    NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM %@ %@ ",[modelCls t_tableName], [self SQLWithConditions:conditions]];
    return sql;
}
@end
