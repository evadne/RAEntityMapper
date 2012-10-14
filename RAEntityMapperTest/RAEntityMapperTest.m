//
//  RAEntityMapperTest.m
//  RAEntityMapperTest
//
//  Created by Evadne Wu on 10/13/12.
//  Copyright (c) 2012 Radius. All rights reserved.
//

#import "RAEntityMapperTest.h"
#import "RAEntityMapper.h"
#import "RAEntityMapperDelegate.h"

@interface RAEntityMapperTest () <RAEntityMapperDelegate>
@property (nonatomic, readonly, strong) RAEntityMapper *entityMapper;
@property (nonatomic, readonly, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly, strong) NSManagedObjectContext *context;
@property (nonatomic, readonly, strong) NSManagedObjectModel *model;
@property (nonatomic, readonly, strong) NSEntityDescription *entity;
@property (nonatomic, readonly, strong) NSArray *representations;
@end

@implementation RAEntityMapperTest
@synthesize entityMapper = _entityMapper;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize context = _context;
@synthesize model = _model;
@synthesize entity = _entity;
@synthesize representations = _representations;

- (NSUInteger) numberOfTestIterationsForTestWithSelector:(SEL)testMethod {

	return 100;

}

- (void) setUp {
	
	[super setUp];
	
	//	?
	
}

- (void) tearDown {

	_entityMapper.delegate = nil;
	_entityMapper = nil;
	_persistentStoreCoordinator = nil;
	_context = nil;
	_model = nil;
	_entity = nil;
	_representations = nil;
	
	[super tearDown];
	
}

- (RAEntityMapper *) entityMapper {

	if (!_entityMapper) {
	
		_entityMapper = [[RAEntityMapper alloc] initWithRepresentations:self.representations entity:self.entity context:self.context options:nil];
		
		_entityMapper.delegate = self;
		
	}
	
	return _entityMapper;

}

- (NSString *) entityMapper:(RAEntityMapper *)mapper identifierForRepresentation:(NSDictionary *)representation ofEntity:(NSEntityDescription *)entity {

	return RAEntityMapperDefaultIdentifierForRepresentationOfEntity(self, mapper, representation, entity);

}

- (NSString *) entityMapper:(RAEntityMapper *)mapper identifierKeyForEntity:(NSEntityDescription *)entity {

	return RAEntityMapperDefaultIdentifierKeyForEntity(self, mapper, entity);
	
}

- (NSDictionary *) entityMapper:(RAEntityMapper *)mapper attributesForRepresentation:(NSDictionary *)representation ofEntity:(NSEntityDescription *)entity {

	return RAEntityMapperDefaultAttributesForRepresentationOfEntity(self, mapper, representation, entity);

}

- (NSDictionary *) entityMapper:(RAEntityMapper *)mapper relationshipRepresentationsForRepresentation:(NSDictionary *)representation ofEntity:(NSEntityDescription *)entity {

	return RAEntityMapperDefaultRelationshipRepresentationsForRepresentationOfEntity(self, mapper, representation, entity);

}

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {

	if (!_persistentStoreCoordinator) {
	
		_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
	
	}
	
	return _persistentStoreCoordinator;

}

- (NSManagedObjectContext *) context {

	if (!_context) {
	
		_context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		_context.persistentStoreCoordinator = self.persistentStoreCoordinator;
	
	}
	
	return _context;

}

- (NSManagedObjectModel *) model {

	if (!_model) {
	
		_model = [NSManagedObjectModel new];
		_model.entities = @[
			((^{
				NSEntityDescription *entity = [NSEntityDescription new];
				entity.name = @"A";
				entity.properties = @[
					((^{
						NSAttributeDescription *attribute = [NSAttributeDescription new];
						attribute.attributeType = NSStringAttributeType;
						attribute.name = @"id";
						return attribute;
					})()),
					((^{
						NSAttributeDescription *attribute = [NSAttributeDescription new];
						attribute.attributeType = NSStringAttributeType;
						attribute.name = @"name";
						return attribute;
					})()),
					((^{
						NSAttributeDescription *attribute = [NSAttributeDescription new];
						attribute.attributeType = NSStringAttributeType;
						attribute.name = @"title";
						return attribute;
					})()),
					((^{
						NSAttributeDescription *attribute = [NSAttributeDescription new];
						attribute.attributeType = NSDateAttributeType;
						attribute.name = @"date";
						return attribute;
					})()),
					((^{
						NSRelationshipDescription *relationship = [NSRelationshipDescription new];
						relationship.destinationEntity = entity;
						relationship.inverseRelationship = relationship;
						relationship.name = @"representationEntity";
						return relationship;
					})())
				];
				entity.userInfo = @{
					RAEntityUserInfoIdentifierKeyPathAttributeName: @"id"
				};
				return entity;
			})())
		];

	}
	
	return _model;

}

- (NSEntityDescription *) entity {

	if (!_entity) {
	
		_entity = [[self.model entitiesByName] objectForKey:@"A"];
	
	}
	
	return _entity;

}

- (NSArray *) representations {

	if (!_representations) {
	
		_representations = @[
		
			@{
				@"id": @1048576,
				@"title": @"Title",
				@"date": @"2012-10-13T17:51:12Z"
			},
		
			@{
				@"id": @1048576,
				@"title": @"Title Overwrite"
			},
			
			@{
				@"id": @4096,
				@"title": @"Title 4096",
				@"date": @"2012-10-13T18:15:46Z",
				@"representationEntity": @{
					@"id": @8192,
					@"date": @"2008-10-30T12:15:46Z"
				}
			},
			
		];
	
	}
	
	return _representations;

}

- (void) testImport {

	__block BOOL finished = NO;
	
	finished = NO;
	
	[self.entityMapper invokeWithCompletion:^(RAEntityMapper *mapper, NSArray *objects, NSError *error) {
	
		BOOL isMapperClass = [mapper isKindOfClass:[RAEntityMapper class]];
		STAssertTrue(isMapperClass, @"self pointer should point to RAEntityMapper or a subclass.");
		STAssertNil(error, @"Should not throw error.");
		
		for (NSManagedObject *object in objects) {
			STAssertTrue([object isKindOfClass:[NSManagedObject class]], @"Must be a managed object.");
			STAssertTrue([object isKindOfClass:NSClassFromString([self.entity managedObjectClassName])], @"Must be of the correct class.");
		}
		
		finished = YES;
		
	}];
	
	while (!finished)
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:.125]];

}

@end
