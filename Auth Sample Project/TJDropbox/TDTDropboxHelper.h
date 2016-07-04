//
//  TDTDropboxHelper.h
//  TJDropbox
//
//  Created by Tung Duong Thanh on 6/28/16.
//  Copyright © 2016 tijo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TDTDropboxAuthenicatedModel : NSObject

@property (nonatomic, strong) NSString *token;

- (instancetype)initWithToken:(NSString *)token;

@end

@interface TDTDropboxHelper : NSObject
/**
 *  Authen to Dropbox with completion will be fired after authen complete (after dismiss authen view controller)
 *  - Cache authenticated model after authen complete
 *  - If user already authen to Dropbox before, call complete block immediatedly
 *
 *  @param controller controller which authentication start from
 *  @param completion completion block
 */
+ (void)authenticateFromViewController:(UIViewController *)controller completion:(void(^)(NSError *error, TDTDropboxAuthenicatedModel *authenticatedModel))completion;

+ (BOOL)handleOpenURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options;

/**
 *  Remove token accquired for app
 */
+ (void)signOut;

/**
 *  Upload file to dropbox
 *
 *  @param controller View Controller which events fired from
 *  @param localPath  file local path
 *  @param remotePath target remote path
 *  @param completion completion block
 */
+ (void)uploadFileFromController:(UIViewController *)controller localPath:(NSString *)localPath remotePath:(NSString *)remotePath completion:(void(^)(NSError *error, NSDictionary *parsedResponse))completion;
@end
