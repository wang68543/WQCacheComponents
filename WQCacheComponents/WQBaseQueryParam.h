//
//  WQBaseQueryParam.h
//  WQCacheDemo
//
//  Created by WangQiang on 2017/5/27.
//  Copyright © 2017年 WQCacheKit. All rights reserved.
//

#import <Foundation/Foundation.h>

//NSURLRequestUseProtocolCachePolicy = 0,
//
//NSURLRequestReloadIgnoringLocalCacheData = 1,
//NSURLRequestReloadIgnoringLocalAndRemoteCacheData = 4, // Unimplemented
//NSURLRequestReloadIgnoringCacheData = NSURLRequestReloadIgnoringLocalCacheData,
//
//NSURLRequestReturnCacheDataElseLoad = 2,
//NSURLRequestReturnCacheDataDontLoad = 3,
//
//NSURLRequestReloadRevalidatingCacheData = 5
typedef NS_ENUM(NSInteger , WQRefreshPolicy) {
    /** 本地先查询 不够的话再去服务器取 取完了然后再从数据库中查询*/
    kRefreshFromDBFirst,
    /** 只读取本地数据库的 */
    kRefreshOnlyFromDB,
    /** 本地直接查询数据库 然后去远程读取 最后存到本地数据库 最后读取数据 */
    kRefreshFromRemoteDependencyDB,
    /** 仅仅只是根据数据库的数据刷新数据库 不读取*/
    kOnlyRefreshDBFromRemoteDependencyDB,
};

typedef NS_ENUM(NSInteger ,WQOrderType) {
    kOrderNone,//不需要排序
    kOrderDescending,//降序 (默认降序)
    kOrderAscending,//升序
};
typedef enum : NSUInteger {
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
    WQConditionValueTypeString,//默认的
    WQConditionValueTypeFloat,
    WQConditionValueTypeInteger,
} WQConditionValueType;

@interface WQQueryCondition : NSObject

/** 查询的关系 */
@property (assign ,nonatomic) WQRelationType relationType;
/** 查询的字段名 */
@property (copy ,nonatomic) NSString *columnName;
@property (copy ,nonatomic) NSString *value;
/** value的类型 */
@property (assign ,nonatomic) WQConditionValueType valueType;

/** 判断条件是否为空 */
- (BOOL)isEmpty;
/** 判断 当前条件模型是否可用 */
- (BOOL)isConditionLegal;
/** 返回SQL语句 */
- (NSString *)SQLFormat;
/** 初始化 */
+ (instancetype)conditionColumnName:(NSString *)columnName relationship:(WQRelationType)relation toValue:(NSString *)value;
/** 根据枚举类型获取字符串的关系表达形式 */
+ (NSString *)columnToValueRelationWithType:(WQRelationType)relationType;
@end

//@"SELECT * ,MAX(savedate) FROM t_chat GROUP BY IMEI;"
//@"SELECT imei, COUNT(*) FROM t_chat WHERE readState = %d GROUP BY imei;"
@interface WQBaseQueryParam : NSObject

/** 返回模型的类型 */
- (Class)modelClass;

/** 首要的查询条件 */
@property (strong ,nonatomic) WQQueryCondition *sameLimit;

/** 查询时候的 排序字段 */
@property (copy ,nonatomic) NSString *orderByKey;
/** 偏移的条数 */
@property (assign ,nonatomic) NSInteger offset;
/** 每页的条数 */
@property (assign ,nonatomic) NSInteger limit;
/** 排序 */
@property (assign ,nonatomic) WQOrderType orderType;

@property (assign ,nonatomic) WQRefreshPolicy  refreshPolicy;

/** 从服务器请求的数量 */
@property (assign ,nonatomic) NSUInteger countsFromServer;
/** 数据库表名字 (组建SQL语句的时候使用) */
-(NSString *)t_tableName;

//所有的SQL语句拼接规则 都是当前关键词结束添加一个空格

/** 单纯条件SQL语句 */
-(NSString *)conditionSQLString;

/** 拼接子类添加的属性 */
-(NSString *)formatExtraConditions;

/** 查询模型转换为SQL查询参数 */
- (NSString *)queryParamFormatSQLString;

/** SQL删除语句配置 */
- (NSString *)deleteParamFormatSQLString;

///** 读取最新的一条数据SQL语句 */
//- (NSString *)readLatestSQLString;
//
///** 读取最旧的一条数据SQL语句 */
//- (NSString *)readOldestSQLString;

/** 根据参数生成更新语句 */
-(NSString *)updateSQL:(id)model
                     updateKeys:(NSArray *)keys;


/** 数据库存储目录 */
+(NSString *)db_cacheDirectory;
/** 数据库名字 */
+(NSString *)db_name;

@end
