//
//  LinkedInAPI.h
//  LinkedInAPI
//
//  Created by Chris Eidhof on 6/27/12.
//  Copyright (c) 2012 Chris Eidhof. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^APIInitializationCallback)(NSURL* url);
typedef void(^APICallback)(id result);
typedef void(^APIEmptyCallback)();
typedef void(^APIFail)(NSError* error);

@protocol LinkedInAPIDelegate <NSObject>

- (void)userRefusedAccess;
- (void)userLoggedInWithToken:(NSString*)token secret:(NSString*)secret;

@end

@interface LinkedInAPI : NSObject <UIWebViewDelegate>

- (id)initWithConsumerKey:(NSString*)key 
                   secret:(NSString*)secret;

- (void)startAuthentication:(APIInitializationCallback)callback;
- (void)setToken:(NSString*)token_ andSecret:(NSString*)secret_;
- (void)getConnections:(APICallback)callback failureHandler:(APIFail)failureHandler;
- (void)getProfile:(APICallback)callback failureHandler:(APIFail)failureHandler;
- (void)sendMessageWithBody:(NSString*)body 
                      title:(NSString*)title
                  recipient:(NSString*)recipient
                    success:(APIEmptyCallback)success
             failureHandler:(APIFail)failureHandler;


@property (nonatomic,assign) id<LinkedInAPIDelegate> delegate;

@end
