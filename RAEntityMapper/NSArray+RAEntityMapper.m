//
//  NSArray+RAEntityMapper.m
//  RAEntityMapper
//
//  Created by Evadne Wu on 10/13/12.
//  Copyright (c) 2012 Radius. All rights reserved.
//

#import "NSArray+RAEntityMapper.h"

@implementation NSArray (RAEntityMapper)

- (NSArray *) raem_map:(RAEntityMapperMapBlock)block {

	NSCParameterAssert(block);
	if (![self count])
		return self;
	
	NSMutableArray *answer = [NSMutableArray arrayWithCapacity:[self count]];
		
	[self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		
		id object = block(obj, idx, stop);
		if (object)
			[answer addObject:object];
		
	}];
	
	return answer;

}

- (NSArray *) raem_groupBy:(RAEntityMapperGroupByBlock)block {

	__block NSMutableArray *group = nil;
	NSMutableArray *groups = [NSMutableArray array];
	NSMutableArray *unusedObjects = [self mutableCopy];
	
	[self enumerateObjectsUsingBlock: ^ (id obj, NSUInteger idx, BOOL *stop) {
	
		id identifier = block(obj);
		if (!idx) {
		
			group = [NSMutableArray array];
			[groups addObject:group];
		
		} else {
			
			id lastIdentifier = block([self objectAtIndex:(idx - 1)]);
			if (![identifier isEqual:lastIdentifier]) {
				group = [NSMutableArray array];
				[groups addObject:group];
			}
			
		}
		
		[group addObject:obj];
		[unusedObjects removeObject:obj];
	
	}];
	
	for (NSDictionary *unusedObject in unusedObjects) {
		[groups addObject:@[unusedObject]];
	}
	
	return groups;

}

@end
