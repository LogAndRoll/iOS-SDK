//
//  LRMain.h
//  LogAndRoll-SDK
//
//  Created by Peter Willemsen on 27-10-13.
//  Copyright (c) 2013 CodeBuffet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LRMain : NSObject

FOUNDATION_EXPORT void LogNRoll(NSString *tag, NSString *format, ...) NS_FORMAT_FUNCTION(2,3);

+ (void) launchWithApplicationName: (NSString*) appName andAPIKey: (NSString*) key;

@end
