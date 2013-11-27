//
//  LRMain.m
//  LogAndRoll-SDK
//
//  Created by Peter Willemsen on 27-10-13.
//  Copyright (c) 2013 CodeBuffet. All rights reserved.
//

#import "LRMain.h"
#import "LRLogger.h"
#import "Constants.h"

@interface LRMain ()

@end

@implementation LRMain

static LRLogger *logger;

+ (void)launchWithApplicationName:(NSString *)appName andAPIKey:(NSString *)key
{
    logger = [LRLogger sharedLogger];
    logger.appName = appName;
    logger.APIKey = key;
    
    NSLog(@"********************************************");
    NSLog(@"Log & Roll v%@", LR_VERSION);
    NSLog(@"CodeBuffet original");
    NSLog(@"Connected & Active");
    NSLog(@"Current Protocol: CodeBuffet BlobRequests");
    NSLog(@"********************************************");
    
    LogNRoll(kTagAppState, @"Just opened %@", appName);
}

void LogNRoll(NSString *tag, NSString *format, ...)
{
    va_list ap;
    va_start (ap, format);
    NSString *body = [[NSString alloc] initWithFormat: format arguments: ap];
    va_end (ap);
    [LRLogger logTag:tag andMessage:body];
}

@end
