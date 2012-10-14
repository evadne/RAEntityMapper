//
//  NSArray+RAEntityMapper.h
//  RAEntityMapper
//
//  Created by Evadne Wu on 10/13/12.
//  Copyright (c) 2012 Radius. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id (^RAEntityMapperMapBlock)(id obj, NSUInteger idx, BOOL *stop);
typedef id (^RAEntityMapperGroupByBlock)(id obj);

@interface NSArray (RAEntityMapper)

- (NSArray *) raem_map:(RAEntityMapperMapBlock)block;
- (NSArray *) raem_groupBy:(RAEntityMapperGroupByBlock)block;

@end
