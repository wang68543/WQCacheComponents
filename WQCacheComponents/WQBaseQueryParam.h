//
//  WQBaseQueryParam.h
//  WQCacheDemo
//
//  Created by WangQiang on 2017/5/27.
//  Copyright © 2017年 WQCacheKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WQSQLCondition.h"

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
typedef NS_ENUM(NSInteger , WQDBAction) {
    WQDBActionQuery,
    WQDBActionDelete,
};
 

@interface WQBaseQueryParam : NSObject
/** 返回模型的类型 */
 
@property (assign  ,nonatomic) Class modelClass;
@property (strong  ,nonatomic) NSMutableArray *conditions;
 
/** 偏移的条数 */
@property (assign ,nonatomic) NSInteger offset;
/** 每页的条数 */
@property (assign ,nonatomic) NSInteger limit;


@property (assign ,nonatomic) WQRefreshPolicy  refreshPolicy;

/** 从服务器请求的数量 */
@property (assign ,nonatomic) NSUInteger countsFromServer;

- (NSString *)actionSQL:(WQDBAction)actionType;

/** 数据库存储目录 */
+(NSString *)db_cacheDirectory;
/** 数据库名字 */
+(NSString *)db_name;


@end
