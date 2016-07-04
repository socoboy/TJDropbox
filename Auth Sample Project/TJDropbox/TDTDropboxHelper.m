//
//  TDTDropboxHelper.m
//  TJDropbox
//
//  Created by Tung Duong Thanh on 6/28/16.
//  Copyright © 2016 tijo. All rights reserved.
//

#import "TDTDropboxHelper.h"

#import "TJDropbox.h"
#import "TJDropboxAuthenticationViewController.h"

#import <SafariServices/SafariServices.h>

#pragma mark + Static
static NSString *const kClientIdentifier = @"l84gohskk5skmtp";
static NSString *const kRedirectURLString = @"demoappv2://dropboxauth";
static NSString *const kDropboxTokenCachedKey = @"DROPBOX_TOKEN_CACHED";

#pragma mark - TDTDropboxHelper
@interface TDTDropboxHelper () <TJDropboxAuthenticationViewControllerDelegate>

@property (nonatomic, strong) TDTDropboxAuthenicatedModel *authenticatedModel;
@property (nonatomic, copy, readwrite) void(^authenticationCompletionBlock)(NSError *error, TDTDropboxAuthenicatedModel *authenticatedModel);
@property (nonatomic, weak) UIViewController *fromController;
@property (nonatomic) BOOL isAuthenticating;

+ (instancetype)shared;

@end

@implementation TDTDropboxHelper

#pragma mark + Singleton
+ (instancetype)shared {
    static TDTDropboxHelper *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once( &onceToken, ^{
        shared = [[TDTDropboxHelper alloc] init];
    } );
    return shared;
}

#pragma mark + Authentication
+ (void)authenticateFromViewController:(UIViewController *)controller completion:(void (^)(NSError *, TDTDropboxAuthenicatedModel *))completion {
    TDTDropboxAuthenicatedModel *authenticatedModel = [[self shared] authenticatedModel];
    if (authenticatedModel) {
        if (completion) {
            completion(nil, authenticatedModel);
        }
    } else {
        // authentication process
        [[self shared] startAuthenticationProcessFromController:controller completion:completion];
    }
}

- (void)startAuthenticationProcessFromController:(UIViewController *)controller completion:(void (^)(NSError *, TDTDropboxAuthenicatedModel *))completion {
    _fromController = controller;
    _authenticationCompletionBlock = completion;
    _isAuthenticating = YES;
    
    NSURL *appAuthURL = [TJDropbox dropboxAppAuthenticationURLWithClientIdentifier:kClientIdentifier];
    if ([[UIApplication sharedApplication] canOpenURL:appAuthURL]) {
        // For devices which already installed Dropbox App
        [[UIApplication sharedApplication] openURL:appAuthURL];
    } else if ([SFSafariViewController class]) {
        // for iOS 9 and above
        NSURL *authURL = [TJDropbox tokenAuthenticationURLWithClientIdentifier:kClientIdentifier redirectURL:[NSURL URLWithString:kRedirectURLString]];
        SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:authURL];
        [controller presentViewController:safariViewController animated:YES completion:nil];
    } else {
        // use default authentication view controller
        TJDropboxAuthenticationViewController *authViewController = [[TJDropboxAuthenticationViewController alloc] initWithClientIdentifier:kClientIdentifier redirectURL:[NSURL URLWithString:kRedirectURLString] delegate:self];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:authViewController];
        [controller presentViewController:nav animated:YES completion:nil];
    }
}

- (TDTDropboxAuthenicatedModel *)authenticatedModel {
    if (!_authenticatedModel) {
        NSString *cachedToken = [[NSUserDefaults standardUserDefaults] valueForKey:kDropboxTokenCachedKey];
        if (cachedToken.length) {
            _authenticatedModel = [[TDTDropboxAuthenicatedModel alloc] initWithToken:cachedToken];
        }
    }
    return _authenticatedModel;
}

#pragma mark + Sign out
+ (void)signOut {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kDropboxTokenCachedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
#warning PENDING revoke token
    [[self shared] setAuthenticatedModel:nil];
}

#pragma mark + Upload
+ (void)uploadFileFromController:(UIViewController *)controller localPath:(NSString *)localPath remotePath:(NSString *)remotePath completion:(void (^)(NSError *error, NSDictionary *parsedResponse))completion {
    [self authenticateFromViewController:controller completion:^(NSError *error, TDTDropboxAuthenicatedModel *authenticatedModel) {
        if (error) {
            if (completion) {
                completion(error, nil);
            }
            return;
        }
        
        [TJDropbox uploadFileAtPath:localPath toPath:remotePath accessToken:authenticatedModel.token completion:^(NSDictionary * _Nullable parsedResponse, NSError * _Nullable error) {
            if (completion) {
                completion(error, parsedResponse);
            }
        }];
    }];
}

#pragma mark + Authentication delegate
- (void)dropboxAuthenticationViewController:(TJDropboxAuthenticationViewController *)viewController didAuthenticateWithAccessToken:(NSString *const)accessToken {
    _isAuthenticating = NO;
    [self handleTokenRetrieved:accessToken];
}

+ (BOOL)handleOpenURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options{
    BOOL didHandle = NO;
    if ([[self shared] isAuthenticating]) {
        NSString *accessToken = [TJDropbox accessTokenFromURL:url withRedirectURL:[NSURL URLWithString:kRedirectURLString]];
        if (accessToken) {
            // Success! You've authenticated. Store the token and use it.
            didHandle = YES;
            
            // create authenticated model and save
            [[self shared] handleTokenRetrieved:accessToken];
        } else {
            // authentication failed
            if ([[self shared] authenticationCompletionBlock]) {
                [[self shared] authenticationCompletionBlock]([NSError errorWithDomain:@"Dropbox" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Authentication failed, Unknown reason"}], nil);
            }
        }
        [[self shared] setIsAuthenticating:NO];
    }
    return didHandle;
}

- (void)handleTokenRetrieved:(NSString *)token {
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:kDropboxTokenCachedKey];
    TDTDropboxAuthenicatedModel *authenModel = [[TDTDropboxAuthenicatedModel alloc] initWithToken:token];
    
    [self.fromController dismissViewControllerAnimated:YES completion:^{
        if (self.authenticationCompletionBlock) {
            self.authenticationCompletionBlock(nil, authenModel);
        }
    }];
}
@end


#pragma mark - TDTDropboxAuthenicatedModel
@implementation TDTDropboxAuthenicatedModel

- (instancetype)initWithToken:(NSString *)token {
    self = [self init];
    if (self) {
        _token = token;
    }
    return self;
}

@end