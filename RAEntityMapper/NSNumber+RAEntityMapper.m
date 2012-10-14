//
//  NSNumber+RAEntityMapper.m
//  RAEntityMapper
//
//  Created by Evadne Wu on 10/13/12.
//  Copyright (c) 2012 Radius. All rights reserved.
//

#import "NSObject+RAEntityMapper.h"
#import "NSNumber+RAEntityMapper.h"

@implementation NSNumber (RAEntityMapper)

- (id) ra_valueForAttributeType:(NSAttributeType)type {

	switch (type) {
	
		case NSDecimalAttributeType:
			return [NSDecimalNumber decimalNumberWithDecimal:[self decimalValue]];
		
		case NSStringAttributeType:
			return [self stringValue];
			
		case NSBooleanAttributeType:
			return [NSNumber numberWithBool:[self boolValue]];
		
		default:
			return [super ra_valueForAttributeType:type];
	
	}

}

@end
