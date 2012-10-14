//
//  RAEntityMapperDelegate.m
//  RAEntityMapper
//
//  Created by Evadne Wu on 10/13/12.
//  Copyright (c) 2012 Radius. All rights reserved.
//

#import <objc/runtime.h>
#import "RAEntityMapperDelegate.h"
#import "NSObject+RAEntityMapper.h"

NSString * const RAEntityUserInfoIdentifierKeyPathAttributeName = @"IdentifierKeyPath";

NSString * RAEntityMapperDefaultIdentifierForRepresentationOfEntity (id<RAEntityMapperDelegate> self, RAEntityMapper *mapper, NSDictionary *representation, NSEntityDescription *entity) {

	NSString *key = [self entityMapper:mapper identifierKeyForEntity:entity];
	
	id identifier = [representation valueForKeyPath:key];
	if ([identifier isKindOfClass:[NSString class]])
		return (NSString *)identifier;
		
	if ([identifier isKindOfClass:[NSNumber class]])
		return [(NSNumber *)identifier stringValue];
	
	NSCParameterAssert(NO);
	return nil;

}

NSString * RAEntityMapperDefaultIdentifierKeyForEntity (id<RAEntityMapperDelegate> self, RAEntityMapper *mapper, NSEntityDescription *entity) {

	static NSString *kEntityIdentifierKey = @"RAEntityMapperDefaultIdentifierKeyForEntity() kEntityIdentifierKey";
	
	NSString *key = objc_getAssociatedObject(entity, &kEntityIdentifierKey);
	if (!key) {

		NSDictionary *userInfo = entity.userInfo;
		key = [userInfo objectForKey:RAEntityUserInfoIdentifierKeyPathAttributeName];
		if (!key) {
			
			static NSArray *candidateKeys = nil;
			static dispatch_once_t onceToken;
			dispatch_once(&onceToken, ^{
				candidateKeys = @[@"id", @"identifier", @"url", @"URL"];
			});
			
			for (NSString *attributeName in [entity.attributesByName allKeys]) {
				if ([candidateKeys containsObject:attributeName]) {
					key = attributeName;
					break;
				}
			}
			
		}
		
		NSCParameterAssert(key);
		objc_setAssociatedObject(entity, &kEntityIdentifierKey, key, OBJC_ASSOCIATION_RETAIN);
	
	}
	
	NSCParameterAssert(key);
	return key;

}

NSDictionary * RAEntityMapperDefaultAttributesForRepresentationOfEntity (id<RAEntityMapperDelegate> self, RAEntityMapper *mapper, NSDictionary *representation, NSEntityDescription *entity) {

	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	
	[entity.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSAttributeDescription *attribute, BOOL *stop) {
		
		id value = [representation objectForKey:name];
		if (!value)
			return;
		
		[dictionary setObject:[value ra_valueForAttributeType:attribute.attributeType] forKey:name];
		
	}];
	
	return dictionary;

}

NSDictionary * RAEntityMapperDefaultRelationshipRepresentationsForRepresentationOfEntity (id<RAEntityMapperDelegate> self, RAEntityMapper *mapper, NSDictionary *representation, NSEntityDescription *entity) {

	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	
	[entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSRelationshipDescription *relationship, BOOL *stop) {
		
		id value = [representation objectForKey:name];
		if (!value)
			return;
		
		NSArray *representations = ([value isKindOfClass:[NSOrderedSet class]]) ?
			[(NSOrderedSet *)value array] :
			([value isKindOfClass:[NSSet class]]) ?
				[(NSSet *)value allObjects] :
					[value isKindOfClass:[NSArray class]] ?
						(NSArray *)value :
							@[ value ];
		
		[dictionary setObject:representations forKey:name];
		
	}];
	
	return dictionary;

}
