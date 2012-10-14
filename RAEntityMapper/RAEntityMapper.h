//
//  RAEntityMapper.h
//  RAEntityMapper
//
//  Created by Evadne Wu on 10/13/12.
//  Copyright (c) 2012 Radius. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RAEntityMapperDelegate.h"

typedef void (^RAEntityMapperCompletionBlock)(RAEntityMapper *self, NSArray *objects, NSError *error);

@interface RAEntityMapper : NSObject

- (instancetype) initWithRepresentations:(NSArray *)representations entity:(NSEntityDescription *)entity context:(NSManagedObjectContext *)context options:(NSDictionary *)options;

- (void) invokeWithCompletion:(RAEntityMapperCompletionBlock)block;

@property (nonatomic, readwrite, weak) id<RAEntityMapperDelegate> delegate;

@end


extern NSString * const RAEntityMapperErrorDomain;
extern NSString * const RAEntityMapperExceptionDomain;
