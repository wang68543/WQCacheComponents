//
//  WQSQLCondition.h
//  WQCacheDemo
//
//  Created by hejinyin on 2017/12/21.
//  Copyright © 2017年 WQCacheKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WQSQLMoelProtocol.h"


//@"SELECT * ,MAX(savedate) FROM t_chat GROUP BY IMEI;"
//@"SELECT imei, COUNT(*) FROM t_chat WHERE readState = %d GROUP BY imei;"
typedef NS_ENUM(NSInteger ,WQOrderType) {
    kOrderNone,//不需要排序
    kOrderDescending,//降序 (默认降序)
    kOrderAscending,//升序
};

typedef enum : NSUInteger {
    WQRelationTypeNone,//其他类型的关系
    /** > */
    WQRelationTypeMore,
    /** >= */
    WQRelationTypeEqualMore,
    /** = */
    WQRelationTypeEqual,
    /** != */
    WQRelationTypeIsNot,
    /** <= */
    WQRelationTypeEqualLess,
    /** < */
    WQRelationTypeLess,

} WQRelationType;


typedef enum : NSUInteger {
    WQConditionValueTypeDefault,
    WQConditionValueTypeString,//默认的
    WQConditionValueTypeFloat,
    WQConditionValueTypeInteger,
    //排序的类型
    WQConditionValueTypeOrderEnum = 100,
} WQConditionValueType;

typedef NS_ENUM(NSInteger,WQConditionConactType) {
    WQConditionConactNone,
    WQConditionConactAND,
    WQConditionConactOR,
    WQConditionConactORDER_BY
};
@class WQSQLCondition;
 @interface WQSQLCondition : NSObject

/** 查询的关系 */
@property (assign ,nonatomic) WQRelationType relationType;
/** 查询的字段名 */
@property (copy ,nonatomic) NSString *columnName;
@property (strong ,nonatomic) id value;
/**
 初始化条件

 @param columnName 对应的数据库字段名
 @param relation 限制条件
 @param value 限制值
 @return SQL语句
 */
+ (instancetype)conditionColumnName:(NSString *)columnName relationship:(WQRelationType)relation toValue:(id)value;
/** 连接前一个的关系 */
@property (assign  ,nonatomic) WQConditionConactType connectBeforeType;

@property (assign  ,nonatomic) WQConditionValueType valueType;

/** 判断条件是否为空 */
- (BOOL)isEmpty;
/** 返回SQL语句 */
- (NSString *)SQLFormat;

/** 拼接条件限制SQL语句 默认 and连接 */
+ (NSString *)SQLWithConditions:(NSArray<WQSQLCondition *>*)conditions;
/** 查询语句 */
+(NSString *)QuerySQL:(Class<WQSQLMoelProtocol>)modelCls conditions:(NSArray<WQSQLCondition *> *)conditions;
+ (NSString *)QuerySQL:(Class<WQSQLMoelProtocol>)modelCls conditions:(NSArray<WQSQLCondition *>*)conditions limit:(NSInteger)limit offset:(NSInteger)offset;
+ (NSString *)DeleteSQL:(Class<WQSQLMoelProtocol>)modelCls conditions:(NSArray<WQSQLCondition *>*)conditions;


@end
