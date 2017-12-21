//
//  WQSQLMoelProtocol.h
//  WQCacheDemo
//
//  Created by WangQiang on 2017/6/5.
//  Copyright © 2017年 WQCacheKit. All rights reserved.
//  数据库存储模型需要遵守的协议

#import <Foundation/Foundation.h>
//#import <FMDB.h>
@protocol WQSQLMoelProtocol <NSObject>
@required

/**
 操作模型必须实现的方法, 通过这个方法获取主键信息
 
 @return 主键字符串
 */
+ (NSString *)primaryKey;

/** 类自定义表名 (当一个模型可能创建多个表名的时候 就使用查询模型的实例化方法来区分) */
+ (NSString *)t_tableName;

@optional

/**
 忽略的字段数组
 
 @return 忽略的字段数组
 */
+ (NSArray *)ignoreColumnNames;

/**
 新字段名称-> 旧的字段名称的映射表格 (数据库迁移的时候使用)
 
 @return 映射表格
 */
+ (NSDictionary *)newNameToOldNameDic;



//* 用于解决遵守协议之后 无法创建协议类
+ (instancetype)alloc;
////TODO:模型解析
////@required
///**
// 解析服务器下载数据的模型(根据请求参数进行)
//
// @param json 数据库返回的json数据
// @param outError 解析错误的结果
// @return 返回解析模型
// */
//+ (NSArray *)parseModelsWithJSON:(id)json error:(NSError **)outError;


@end
