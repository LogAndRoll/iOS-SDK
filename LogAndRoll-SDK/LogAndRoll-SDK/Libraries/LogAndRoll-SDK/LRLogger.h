//
//  LRLogger.h
//  LogAndRoll-SDK
//
//  Created by Peter Willemsen on 27-10-13.
//  Copyright (c) 2013 CodeBuffet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LRLogger : NSObject <NSURLConnectionDataDelegate>

+ (LRLogger*)sharedLogger;
+ (void) logTag: (NSString*) tag andMessage: (NSString*) message;

@property (nonatomic, retain) NSString *appName, *APIKey;

@end
