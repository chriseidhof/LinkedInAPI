//
//  LinkedInAPI.m
//  LinkedInAPI
//
//  Created by Chris Eidhof on 6/27/12.
//  Copyright (c) 2012 Chris Eidhof. All rights reserved.
//

#import "LinkedInAPI.h"
#import "GCOAuth.h"

@interface LinkedInAPI () {
    NSString* consumerKey;
    NSString* consumerSecret;
    NSString *accessToken;
    NSString *tokenSecret;
    NSURL* baseURL;
    NSString* verifier;
    APIInitializationCallback startAuthenticationCallback;
}

@end

static NSString* requestTokenURLString = @"https://api.linkedin.com/uas/oauth/requestToken";
static NSString* accessTokenURLString = @"https://api.linkedin.com/uas/oauth/accessToken";
static NSString* userLoginURLString = @"https://www.linkedin.com/uas/oauth/authorize";    
static NSString* linkedInCallbackURL = @"http://linkedin/oauth";

@implementation LinkedInAPI

@synthesize delegate;

- (id)initWithConsumerKey:(NSString*)key secret:(NSString*)secret {
    self = [super init];
    if(self) {
        consumerKey = key;
        consumerSecret = secret;
        baseURL = [NSURL URLWithString:@"http://api.linkedin.com/v1"]; 
    }
    return self;
}

- (void)setToken:(NSString*)token andSecret:(NSString*)secret {
    accessToken = token;
    tokenSecret = secret;
}

- (void)startAuthentication:(APIInitializationCallback)theCallback {
    startAuthenticationCallback = [theCallback copy];
    [self requestTokenFromProvider];
}

- (NSURLRequest*)requestForGet:(NSString*)path {
    NSMutableURLRequest* request = [self requestForGetWithURL:[baseURL URLByAppendingPathComponent:path]];
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    return request;
}

- (NSMutableURLRequest*)requestForGetWithURL:(NSURL*)url {    
    NSString* path = [url path];
    NSString* host = [url host];
    NSMutableURLRequest* request = [GCOAuth URLRequestForPath:path GETParameters:nil scheme:@"https" host:host consumerKey:consumerKey consumerSecret:consumerSecret accessToken:accessToken tokenSecret:tokenSecret];
    return request;
}

- (NSURLRequest*)requestForPost:(NSString*)path parameters:(id)parameters {
    NSMutableURLRequest* request = [self requestForPostWithURL:[baseURL URLByAppendingPathComponent:path] parameters:nil oauthParameters:nil];
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSData* data = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:NULL];
    NSString *length = [NSString stringWithFormat:@"%lu", (unsigned long)[data length]];
    [request setHTTPBody:data];
    [request setValue:length forHTTPHeaderField:@"Content-Length"];
    return request;
}

- (NSMutableURLRequest*)requestForPostWithURL:(NSURL*)url parameters:(NSDictionary*)parameters oauthParameters:(NSDictionary*)oauthParameters {
    NSString* path = [url path];
    NSString* host = [url host];
    NSMutableURLRequest* request = [GCOAuth URLRequestForPath:path 
                                               POSTParameters:parameters
                                                         host:host
                                                  consumerKey:consumerKey
                                               consumerSecret:consumerSecret
                                                  accessToken:accessToken
                                                  tokenSecret:tokenSecret
                                              oauthParameters:oauthParameters];
    return request;
}

- (NSDictionary*)parseFormEncodedString:(NSString*)string {
    NSArray* keyValuePairs = [string componentsSeparatedByString:@"&"];
    NSMutableDictionary* result = [NSMutableDictionary dictionary];
    for(NSString* item in keyValuePairs) {
        NSArray* keyAndValue = [item componentsSeparatedByString:@"="];
        NSString* key = [[keyAndValue objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString* value = [[keyAndValue objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [result setObject:value forKey:key];
    }
    return result;

}

- (void)requestTokenFromProvider
{
    NSURLRequest* request = [self requestForPostWithURL:[NSURL URLWithString:requestTokenURLString] parameters:nil oauthParameters:nil];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
        if(error) {
            return;
        }
        NSString* responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary* result = [self parseFormEncodedString:responseBody];
        accessToken = [result objectForKey:@"oauth_token"];
        tokenSecret = [result objectForKey:@"oauth_token_secret"];
        NSString* tokenComponent = [NSString stringWithFormat:@"?oauth_token=%@", [accessToken stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURL* loginURL = [NSURL URLWithString:[userLoginURLString stringByAppendingString:tokenComponent]];
        startAuthenticationCallback(loginURL);
    }];
}


#pragma mark UIWebViewDelegate methods

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType 
{
	NSURL *url = request.URL;
	NSString *urlString = url.absoluteString;
        
    BOOL requestForCallbackURL = ([urlString rangeOfString:linkedInCallbackURL].location != NSNotFound);
    if ( requestForCallbackURL )
    {
        BOOL userAllowedAccess = ([urlString rangeOfString:@"user_refused"].location == NSNotFound);
        if (userAllowedAccess) {            
            NSDictionary* parameters = [self parseFormEncodedString:[url query]];
            verifier = [parameters objectForKey:@"oauth_verifier"];
            [self accessTokenFromProvider];
        }
        else {
            [delegate userRefusedAccess];
        }
    }
	return YES;
}

- (void)accessTokenFromProvider {
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:verifier, @"oauth_verifier", nil];
    NSURLRequest* request = [self requestForPostWithURL:[NSURL URLWithString:accessTokenURLString] parameters:nil oauthParameters:parameters];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
        if(error) {
            return;
        }
        NSString* responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary* result = [self parseFormEncodedString:responseBody];
        accessToken = [result objectForKey:@"oauth_token"];
        tokenSecret = [result objectForKey:@"oauth_token_secret"];
        [delegate userLoggedInWithToken:accessToken secret:tokenSecret];
    }];
}

#pragma mark API Methods

- (void)apiMethodForPath:(NSString*)path success:(APICallback)succesHandler failureHandler:(APIFail)failureHandler {
    NSURLRequest* request = [self requestForGet:path];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
        if(error) {
            failureHandler(error);
            return;
        }
        id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if(error) {
            failureHandler(error);
            return;
        }
        succesHandler(result);
    }];
}

- (void)postApiMethodForPath:(NSString*)path parameters:(id)parameters success:(APICallback)succesHandler failureHandler:(APIFail)failureHandler {
    NSURLRequest* request = [self requestForPost:path parameters:parameters];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
        if(error) {
            failureHandler(error);
            return;
        }
        id result = [data length] ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
        if(error) {
            failureHandler(error);
            return;
        }
        succesHandler(result);
    }];
}

- (void)getConnections:(APICallback)success failureHandler:(APIFail)failureHandler {
    [self apiMethodForPath:@"people/~/connections" success:^(id result) {
        success([result objectForKey:@"values"]);
    } failureHandler:failureHandler];
}

- (void)getProfile:(APICallback)success failureHandler:(APIFail)failureHandler {
    [self getProfile:success failureHandler:failureHandler fields:nil];
}

- (void)getProfile:(APICallback)success failureHandler:(APIFail)failureHandler fields:(NSArray*)fields {
    NSString* path = @"people/~";
    if([fields count]) {
        NSString* joined = [fields componentsJoinedByString:@","];
        NSString* fieldSelector = [NSString stringWithFormat:@":(%@)", joined];
        path = [path stringByAppendingString:fieldSelector];
    }
    [self apiMethodForPath:path success:^(id result) {
        success(result);
    } failureHandler:failureHandler];
}

- (void)sendMessageWithBody:(NSString*)body title:(NSString*)title recipient:(NSString*)recipient success:(APIEmptyCallback)success failureHandler:(APIFail)failureHandler {
    NSDictionary* recipientPath = [NSDictionary dictionaryWithObject:recipient forKey:@"_path"];
    NSDictionary* person = [NSDictionary dictionaryWithObject:recipientPath forKey:@"person"];
    NSDictionary* values = [NSDictionary dictionaryWithObject:
                             [NSArray arrayWithObject:person] forKey:@"values"];
    NSDictionary *message = [NSDictionary dictionaryWithObjectsAndKeys:
                            values, @"recipients", 
                            body, @"body",
                            title, @"subject",
                            nil];
    NSLog(@"message: %@", message);
    [self postApiMethodForPath:@"people/~/mailbox" parameters:message success:^(id result) {
        success();
    } failureHandler:failureHandler];
}

@end
