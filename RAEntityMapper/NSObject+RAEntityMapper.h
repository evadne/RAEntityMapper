//
//  NSObject+RAEntityMapper.h
//  RAEntityMapper
//
//  Created by Evadne Wu on 10/13/12.
//  Copyright (c) 2012 Radius. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NSObject (RAEntityMapper)

- (id) ra_valueForAttributeType:(NSAttributeType)type;

@end
