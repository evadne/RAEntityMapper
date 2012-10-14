//
//  RAEntityMapper.m
//  RAEntityMapper
//
//  Created by Evadne Wu on 10/13/12.
//  Copyright (c) 2012 Radius. All rights reserved.
//

#import "RAEntityMapper.h"
#import "NSArray+RAEntityMapper.h"

@interface RAEntityMapper () <RAEntityMapperDelegate>
@property (nonatomic, readonly, strong) NSArray *representations;
@property (nonatomic, readonly, strong) NSEntityDescription *entity;
@property (nonatomic, readonly, strong) NSManagedObjectContext *context;
@end

@implementation RAEntityMapper

+ (dispatch_queue_t) dispatchQueue {
	
	static dispatch_once_t onceToken;
	static dispatch_queue_t queue;
	dispatch_once(&onceToken, ^{
		queue = dispatch_queue_create("RAEntityMapperKeepAliveQueue", DISPATCH_QUEUE_SERIAL);
	});
	
	return queue;

}

+ (NSMutableSet *) livingObjects {
	
	static dispatch_once_t onceToken;
	static NSMutableSet *set;
	dispatch_once(&onceToken, ^{
		set = [NSMutableSet set];
	});
	
	return set;

}

- (instancetype) initWithRepresentations:(NSArray *)representations entity:(NSEntityDescription *)entity context:(NSManagedObjectContext *)context options:(NSDictionary *)options {

	NSCParameterAssert(representations);
	NSCParameterAssert(entity);
	NSCParameterAssert(context);
	
	for (NSDictionary *representation in representations)
		NSCParameterAssert([representation isKindOfClass:[NSDictionary class]]);
	
	self = [super init];
	if (!self)
		return nil;
	
	_representations = representations;
	_entity = entity;
	_context = context;
	
	return self;

}

- (id) init {

	return [self initWithRepresentations:nil entity:nil context:nil options:nil];

}

- (void) invokeWithCompletion:(RAEntityMapperCompletionBlock)block {

	NSCParameterAssert(self.delegate);
	NSCParameterAssert(block);
	
	NSArray *representations = self.representations;
	NSEntityDescription *entity = self.entity;
	NSManagedObjectContext *context = self.context;
	
	if (![representations count]) {
		block(self, nil, nil);
		return;
	}
	
	__weak typeof(self.delegate) wDelegate = self.delegate;
	__weak typeof(self) wSelf = self;
		
	dispatch_sync([[self class] dispatchQueue], ^{
		
		NSCParameterAssert(![[[self class] livingObjects] containsObject:self]);
		[[[self class] livingObjects] addObject:self];
		NSCParameterAssert([[[self class] livingObjects] containsObject:self]);

	});
	
	[context performBlockAndWait:^{
	
		NSCParameterAssert(wDelegate);
		NSCParameterAssert(wSelf);
		
		NSString *identifierKey = [wDelegate entityMapper:wSelf identifierKeyForEntity:entity];
		NSCParameterAssert(identifierKey);

		NSArray *identifiersInRepresentations = [representations raem_map:^(NSDictionary *representation, NSUInteger idx, BOOL *stop) {
			NSCParameterAssert([representation isKindOfClass:[NSDictionary class]]);
			return [wDelegate entityMapper:wSelf identifierForRepresentation:representation ofEntity:entity];
		}];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		fetchRequest.returnsObjectsAsFaults = NO;
		fetchRequest.entity = entity;
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(%K IN %@)", identifierKey, identifiersInRepresentations];
		fetchRequest.sortDescriptors = @[
			[NSSortDescriptor sortDescriptorWithKey:identifierKey ascending:YES]
		];
		
		NSError *existingEntitiesFetchingError;
		NSArray *existingObjects = [context executeFetchRequest:fetchRequest error:&existingEntitiesFetchingError];
		
		if (!existingObjects) {
			block(wSelf, nil, existingEntitiesFetchingError);
			dispatch_sync([[wSelf class] dispatchQueue], ^{
				[[[wSelf class] livingObjects] removeObject:wSelf];
			});
			return;
		}
		
		NSUInteger numberOfExistingObjects = [existingObjects count];
		NSManagedObject *currentObject = numberOfExistingObjects ?
			[existingObjects objectAtIndex:0] :
			nil;

		__block NSUInteger currentObjectIndex = -1;
		NSManagedObject * (^nextObject)() = ^ {
		
			if (!currentObject) {
				return (id)nil;
			}

			currentObjectIndex++;
			
			if (currentObjectIndex == numberOfExistingObjects) {
				return (id)nil;
			}
			
			return (id)[existingObjects objectAtIndex:currentObjectIndex];
			
		};
		
		id (^identifier)(id) = ^ (id object) {
			
			if ([object isKindOfClass:[NSManagedObject class]]) {
				
				NSManagedObject *managedObject = (NSManagedObject *)object;
				NSString *objectIdentifierKey = (managedObject.entity == entity) ?
					identifierKey :
					[wDelegate entityMapper:wSelf identifierKeyForEntity:managedObject.entity];
				
				return [managedObject valueForKey:objectIdentifierKey];
				
			} else if ([object isKindOfClass:[NSDictionary class]]) {
				
				return (id)[wDelegate entityMapper:wSelf identifierForRepresentation:(NSDictionary *)object ofEntity:entity];
				
			}
			
			return object;
		
		};
		
		NSComparisonResult (^compare)(id, id) = ^ (id lhs, id rhs) {
			
			return [identifier(lhs) compare:identifier(rhs)];
			
		};
		
		NSMutableArray *answer = [representations mutableCopy];
		NSArray *sortedRepresentations = [representations sortedArrayUsingComparator:compare];
		NSArray *representationArrays = [sortedRepresentations raem_groupBy:^id(id obj) {
			return identifier(obj);
		}];
		
		for (NSArray *representationArray in representationArrays) {
		
			NSDictionary *representation = [representationArray objectAtIndex:0];
			if (![representation isKindOfClass:[NSDictionary class]]) {
				
				NSLog(@"%s: Representation is %@ not a dictionary", __PRETTY_FUNCTION__, representation);
				
				continue;
				
			}
			
			//	When the dictionary has a marker that is ahead of the entity, move on to the next entity.  The marker of the dictionary is guaranteed to match, or fall behind the current entity.
			
			if (currentObject) {
				
				while (NSOrderedAscending == compare(currentObject, representation)) {
					
					currentObject = nextObject();
					if (!currentObject) {
						break;
					}
					
				}
				
			}
			
			NSDictionary *keysToValues = nil;
			if ([representationArray count] == 1) {
				
				keysToValues = [representationArray lastObject];
				
			} else {
				
				NSMutableDictionary *answer = [NSMutableDictionary dictionary];
				for (NSDictionary *representation in representationArray) {
					[answer addEntriesFromDictionary:representation];
				}
				
				keysToValues = answer;
				
			}
			
			NSManagedObject *touchedObject = nil;
			if (currentObject && (compare(currentObject, representation) == NSOrderedSame)) {
				
				touchedObject = currentObject;
				
			} else {
				
				Class class = NSClassFromString([entity managedObjectClassName]);
				touchedObject = [(NSManagedObject *)[class alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
									
			}
			
			[touchedObject setValue:identifier(keysToValues) forKey:identifierKey];
			[touchedObject setValuesForKeysWithDictionary:[wDelegate entityMapper:wSelf attributesForRepresentation:keysToValues ofEntity:entity]];
			
			[[answer indexesOfObjectsPassingTest: ^ (id obj, NSUInteger idx, BOOL *stop) {
			
				if ([obj isKindOfClass:[NSDictionary class]])
					if ([identifier(obj) isEqual:identifier(representation)])
						return YES;
				
				return NO;
			
			}] enumerateIndexesUsingBlock: ^ (NSUInteger idx, BOOL *stop) {

				[answer replaceObjectAtIndex:idx withObject:touchedObject];
		
			}];
			
			[[wDelegate entityMapper:wSelf relationshipRepresentationsForRepresentation:keysToValues ofEntity:entity] enumerateKeysAndObjectsUsingBlock:^(NSString *relationshipName, NSArray *representations, BOOL *stop) {
				
				NSCParameterAssert(relationshipName);
				NSCParameterAssert([representations isKindOfClass:[NSArray class]]);
				
				NSRelationshipDescription *relationship = [entity.relationshipsByName objectForKey:relationshipName];
				NSCParameterAssert(relationship);
				NSCParameterAssert(relationship.entity == entity);
				
				if (![representations count]) {
					[touchedObject setValue:nil forKey:relationship.name];
					return;
				}
				
				RAEntityMapper *mapper = [[[wSelf class] alloc] initWithRepresentations:representations entity:relationship.destinationEntity context:context options:nil];
				mapper.delegate = wSelf;
				
				if (![relationship isToMany]) {
					
					NSCParameterAssert([representations count] == 1);
					[mapper invokeWithCompletion:^(RAEntityMapper *self, NSArray *objects, NSError *error) {
					
						for (NSManagedObject *object in objects)
							NSCParameterAssert([object isKindOfClass:[NSManagedObject class]]);
						
						NSCParameterAssert([objects count] == 1);
						NSCParameterAssert(!error);
						[touchedObject setValue:[objects lastObject] forKey:relationship.name];
						
					}];
					
				} else {
				
					[mapper invokeWithCompletion:^(RAEntityMapper *self, NSArray *objects, NSError *error) {
					
						for (NSManagedObject *object in objects)
							NSCParameterAssert([object isKindOfClass:[NSManagedObject class]]);
						
						NSCParameterAssert(!error);
						if ([relationship isOrdered]) {
							
							[touchedObject setValue:[NSOrderedSet orderedSetWithArray:objects] forKey:relationship.name];
							
						} else {
							
							[touchedObject setValue:[NSSet setWithArray:objects] forKey:relationship.name];
							
						}
						
					}];
					
				}
				
			}];
			
		}
		
		Class entityManagedObjectClass = NSClassFromString([entity managedObjectClassName]);
		for (NSManagedObject *object in answer) {
			NSCParameterAssert([object isKindOfClass:entityManagedObjectClass]);
		}
		
		block(wSelf, answer, nil);
		
		dispatch_sync([[wSelf class] dispatchQueue], ^{
			NSCParameterAssert([[[self class] livingObjects] containsObject:self]);
			[[[wSelf class] livingObjects] removeObject:wSelf];
			NSCParameterAssert(![[[self class] livingObjects] containsObject:self]);
		});

	}];
	
}

- (NSString *) entityMapper:(RAEntityMapper *)mapper identifierForRepresentation:(NSDictionary *)representation ofEntity:(NSEntityDescription *)entity {

	return [self.delegate entityMapper:self identifierForRepresentation:representation ofEntity:entity];

}

- (NSString *) entityMapper:(RAEntityMapper *)mapper identifierKeyForEntity:(NSEntityDescription *)entity {

	return [self.delegate entityMapper:self identifierKeyForEntity:entity];

}

- (NSDictionary *) entityMapper:(RAEntityMapper *)mapper attributesForRepresentation:(NSDictionary *)representation ofEntity:(NSEntityDescription *)entity {

	return [self.delegate entityMapper:self attributesForRepresentation:representation ofEntity:entity];

}

- (NSDictionary *) entityMapper:(RAEntityMapper *)mapper relationshipRepresentationsForRepresentation:(NSDictionary *)representation ofEntity:(NSEntityDescription *)entity {

	return [self.delegate entityMapper:self relationshipRepresentationsForRepresentation:representation ofEntity:entity];

}

@end
