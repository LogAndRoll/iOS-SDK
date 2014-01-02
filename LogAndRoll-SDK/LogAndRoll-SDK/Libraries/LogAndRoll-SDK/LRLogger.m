//
//  LRLogger.m
//  LogAndRoll-SDK
//
//  Created by Peter Willemsen on 27-10-13.
//  Copyright (c) 2013 CodeBuffet. All rights reserved.
//

#import "LRLogger.h"
#import "LRMain.h"
#import "Constants.h"

#define kTag @"tag"
#define kMessage @"message"
#define kTimestamp @"timestamp"
#define kLogs @"logs"
#define kDeviceID [[[UIDevice currentDevice] identifierForVendor] UUIDString]

#define MAX_LOGS_IN_MEMORY 50
#define LOG_SEND_INTERVAL 60

#define serverUrl @"https://logroll.in"
#define kHost @"logroll.in"

#define ts() round([[NSDate date] timeIntervalSince1970])

@interface LRLogger ()
{
    void (^currentCallback)(NSString *content, NSError *error);
}

@property (nonatomic, strong) NSMutableData   *buffer;
@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation LRLogger
@synthesize appName, APIKey;

static NSString *logsPath;
static NSString *userAgent;
static NSMutableArray *recentLogs;

static BOOL postingBlobs;

- (void) postDictionary: (NSDictionary*) json toURL: (NSURL*) url callback: (void (^)(NSString *content, NSError *error)) callback
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json
                                                       options:0 // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            NSData *myRequestData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableURLRequest *request = [ [ NSMutableURLRequest alloc ] initWithURL: url ];
            
            [ request setHTTPMethod: @"POST" ];
            [ request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
            [ request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"content-type"];
            [ request setHTTPBody: myRequestData ];
            
            currentCallback = callback;
            dispatch_async(dispatch_get_main_queue(), ^{
                /* create the connection */
                self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
                
                /* ensure the connection was created */
                if (self.connection)
                {
                    /* initialize the buffer */
                    self.buffer = [NSMutableData data];
                    
                    /* start the request */
                    [self.connection start];
                }
            });
            
        });
    }
}

- (NSString *) firstFileAtPath:(NSString *)path
{
    NSError *error = nil;
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:path]
                                                              includingPropertiesForKeys:[NSArray arrayWithObject:NSURLNameKey]
                                                                                 options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                                   error:&error];
    if (directoryContent.count > 0) {
        return [directoryContent[0] path];
    }
    return nil;
}

- (NSString*) WebviewUA
{
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    return [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
}

- (id) init
{
    if (self = [super init]) {
        recentLogs = [NSMutableArray array];
        userAgent = self.WebviewUA;
        NSString *documentsDirectory = [NSHomeDirectory()
                                        stringByAppendingPathComponent:@"Documents"];
        
        if (!logsPath) {
            logsPath = [documentsDirectory
                        stringByAppendingPathComponent:@"LognRoll"];
            NSLog(@"logsPath: %@", logsPath);
            if (![[NSFileManager defaultManager] fileExistsAtPath:logsPath]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:logsPath withIntermediateDirectories:NO attributes:nil error:nil];
            }
        }
        
        postingBlobs = NO;
        
        [self postBlobsTick];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(becomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        [self performSelector:@selector(postBlobsTick) withObject:nil afterDelay:LOG_SEND_INTERVAL];
    }
    return self;
}

- (void) becomeActive: (NSNotification*) note
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self postBlobs];
    });
}

- (void) resignActive: (NSNotification*) note
{
    LogNRoll(kTagAppState, @"Just went to background");
    [LRLogger save];
}

- (void) postBlobsTick
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self postBlobs];
        [self performSelector:@selector(postBlobsTick) withObject:nil afterDelay:LOG_SEND_INTERVAL];
    });
}

- (void) postBlobs
{
    if (postingBlobs) {
        return;
    }
    postingBlobs = YES;
    [LRLogger save];
    NSString *firstLog = [self firstFileAtPath:logsPath];
    if (firstLog) {
        NSMutableDictionary *blob = [NSMutableDictionary dictionaryWithContentsOfFile:firstLog];
        if (blob) {
            NSDictionary *deviceObject = @{
               @"name": [[UIDevice currentDevice] name]
            };
            [blob setObject:deviceObject forKey:@"deviceDetails"];
            NSString *path = [NSString stringWithFormat:@"%@/api/%@/%@/blob/%@", serverUrl, appName, APIKey, kDeviceID];
            
            [self postDictionary:blob toURL:[NSURL URLWithString:path] callback:^(NSString *responseStr, NSError *error) {
                if (error) {
                    NSLog(@"[HTTPClient Error]: %@", error.localizedDescription);
                    postingBlobs = NO;
                }
                else {
                    NSLog(@"Request Successful, response '%@'", responseStr);
                    NSError *error = nil;
                    [[NSFileManager defaultManager] removeItemAtPath:firstLog error:&error];
                    //NSLog(@"removing %@ because it is done. Possible error: %@", firstLog, error);
                    postingBlobs = NO;
                    if ([self firstFileAtPath:logsPath]) {
                        // If there is more try to send those as well
                        [self postBlobs];
                    }
                }
            }];
        } else {
            postingBlobs = NO;
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:firstLog error:&error];
            NSLog(@"removing %@ because it is invalid. Possible error: %@", firstLog, error);
        }
    } else {
        postingBlobs = NO;
    }
}

// to deal with self-signed certificates
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
	return [protectionSpace.authenticationMethod
			isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if ([challenge.protectionSpace.authenticationMethod
		 isEqualToString:NSURLAuthenticationMethodServerTrust])
	{
		// we only trust our own domain
		if ([challenge.protectionSpace.host isEqualToString:kHost])
		{
			NSURLCredential *credential =
            [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
			[challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
		}
	}
    
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    /* clear the connection &amp; the buffer */
    self.connection = nil;
    self.buffer     = nil;
    
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    
    if (currentCallback) {
        currentCallback(nil, error);
        currentCallback = nil;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    /* reset the buffer length each time this is called */
    [self.buffer setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    /* Append data to the buffer */
    [self.buffer appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    /* dispatch off the main queue for json processing */
    NSString *content = [[NSString alloc] initWithData:_buffer encoding:NSUTF8StringEncoding];
    if (currentCallback) {
        currentCallback(content, nil);
        currentCallback = nil;
    }
}

+ (void) save
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSArray *copy = [[NSArray alloc] initWithArray:recentLogs copyItems:NO];
        if (copy && copy.count > 0) {
            NSString *path = [logsPath stringByAppendingPathComponent:[LRLogger generateBlobName]];
            NSDictionary *dictWithLogs = @{ kLogs: copy };
            [dictWithLogs writeToFile:path atomically:YES];
            NSUInteger len = [recentLogs count];
            NSUInteger copyLen = [copy count];
            NSRange r = NSMakeRange(0, MIN(copyLen, len));
            
            NSLog(@"Saved in %@", path);
            
            [recentLogs removeObjectsInRange:r];
        }
    });
}

+ (void)logTag:(NSString *)tag andMessage:(NSString *)message
{
    NSInteger ts = ts();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSLog(@"LRLog[%@]: %@", tag, message);
        [recentLogs addObject:@{ kTag: tag, kMessage: message, kTimestamp:@(ts) }];
        if (recentLogs.count >= MAX_LOGS_IN_MEMORY) {
            [self save];
        }
    });
}

+ (NSString *) generateBlobName
{
    return [self generateBlobNameWithDate:[NSDate date] andWithIterationNumber:nil];
}

+ (NSString *) generateBlobNameWithDate: (NSDate*) date andWithIterationNumber: (NSNumber*) number
{
    static NSDateFormatter *formatter;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM.dd.yyyy"];
    }
    NSString *file;
    if (number) {
        file = [NSString stringWithFormat:@"blob-%@-%@.txt", [formatter stringFromDate:date], number];
    }
    else {
        file = [NSString stringWithFormat:@"blob-%@.txt", [formatter stringFromDate:date]];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:[logsPath stringByAppendingPathComponent:file]]) {
        if (number) {
            return [self generateBlobNameWithDate:date andWithIterationNumber:@(number.integerValue + 1)];
        } else {
            return [self generateBlobNameWithDate:date andWithIterationNumber:@1];
        }
    }
    return file;
}

+ (LRLogger*)sharedLogger
{
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end