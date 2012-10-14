//
//  RAEntityMapperDelegate.h
//  RAEntityMapper
//
//  Created by Evadne Wu on 10/13/12.
//  Copyright (c) 2012 Radius. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RAEntityMapper;
@protocol RAEntityMapperDelegate <NSObject>

- (NSString *) entityMapper:(RAEntityMapper *)mapper identifierForRepresentation:(NSDictionary *)representation ofEntity:(NSEntityDescription *)entity;

- (NSString *) entityMapper:(RAEntityMapper *)mapper identifierKeyForEntity:(NSEntityDescription *)entity;

- (NSDictionary *) entityMapper:(RAEntityMapper *)mapper attributesForRepresentation:(NSDictionary *)representation ofEntity:(NSEntityDescription *)entity;

- (NSDictionary *) entityMapper:(RAEntityMapper *)mapper relationshipRepresentationsForRepresentation:(NSDictionary *)representation ofEntity:(NSEntityDescription *)entity;

@end

extern NSString * const RAEntityUserInfoIdentifierKeyPathAttributeName;
//	== @"IdentifierKeyPath", if set on userInfo of the entity, used by RAEntityMapperDefaultIdentifierForRepresentationOfEntity() and RAEntityMapperDefaultIdentifierKeyForEntity(); otherwise uses id, identifier, url, URL.

extern NSString * RAEntityMapperDefaultIdentifierForRepresentationOfEntity (id<RAEntityMapperDelegate> self, RAEntityMapper *mapper, NSDictionary *representation, NSEntityDescription *entity);

extern NSString * RAEntityMapperDefaultIdentifierKeyForEntity (id<RAEntityMapperDelegate> self, RAEntityMapper *mapper, NSEntityDescription *entity);

extern NSDictionary * RAEntityMapperDefaultAttributesForRepresentationOfEntity (id<RAEntityMapperDelegate> self, RAEntityMapper *mapper, NSDictionary *representation, NSEntityDescription *entity);

extern NSDictionary * RAEntityMapperDefaultRelationshipRepresentationsForRepresentationOfEntity (id<RAEntityMapperDelegate> self, RAEntityMapper *mapper, NSDictionary *representation, NSEntityDescription *entity);
