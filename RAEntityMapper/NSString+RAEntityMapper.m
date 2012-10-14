//
//  NSString+RAEntityMapper.m
//  RAEntityMapper
//
//  Created by Evadne Wu on 10/13/12.
//  Copyright (c) 2012 Radius. All rights reserved.
//

#import "NSObject+RAEntityMapper.h"
#import "NSString+RAEntityMapper.h"

@implementation NSString (RAEntityMapper)

- (id) ra_valueForAttributeType:(NSAttributeType)type {

	switch (type) {
	
		case NSInteger16AttributeType:
		case NSInteger32AttributeType:
		case NSInteger64AttributeType:
			return [NSNumber numberWithInteger:[self integerValue]];
		
		case NSDoubleAttributeType:
			return [NSNumber numberWithDouble:[self doubleValue]];
		
		case NSFloatAttributeType:
			return [NSNumber numberWithFloat:[self floatValue]];
			
		case NSDecimalAttributeType:
			return [NSDecimalNumber decimalNumberWithString:self];
		
		case NSDateAttributeType: {
		
			static NSString * const key = @"-[NSString ra_valueForAttributeType:] date";
			
			NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
			NSDateFormatter *dateFormatter = [threadDictionary objectForKey:key];
			if (!dateFormatter) {
				dateFormatter = [NSDateFormatter new];
				dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
				[threadDictionary setObject:dateFormatter forKey:key];
			}
			
			NSDate *date = [dateFormatter dateFromString:self];
			if (date)
				return date;
			
			id value;
			NSRange range = (NSRange){ 0, [self length] };
			NSError *error;
			
			BOOL didGetValue = [dateFormatter getObjectValue:&value forString:self range:&range error:&error];
			
			if (didGetValue && !range.location && (range.length == [self length]))
				return value;
				
			NSLog(@"%s: %@ (%@), %@", __PRETTY_FUNCTION__, self, NSStringFromRange(range), error);
			
		}
	
		default:
			return [super ra_valueForAttributeType:type];
	
	}

}

@end
