//
//  TJDropboxTestViewController.m
//  TJDropbox
//
//  Created by Tim Johnsen on 4/27/16.
//  Copyright © 2016 tijo. All rights reserved.
//

#import "TJDropboxTestViewController.h"
#import "TJDropbox.h"
#import "TDTDropboxHelper.h"

@interface TJDropboxTestViewController ()

@property (nonatomic, strong) IBOutlet UIButton *authButton;
@property (nonatomic, strong) IBOutlet UITextView *outputTextView;

@property (nonatomic, copy) NSString *accessToken;

@end

@implementation TJDropboxTestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"TJDropbox Test";
    
    if (self.accessToken.length > 0) {
        [self.authButton setTitle:@"Sign out" forState:UIControlStateNormal];
    } else {
        [self.authButton setTitle:@"Sign in" forState:UIControlStateNormal];
    }
}

- (IBAction)authButtonTapped:(UIButton *)sender
{
    if ([sender.titleLabel.text isEqualToString:@"Sign out"]) {
        self.accessToken = nil;
        [TDTDropboxHelper signOut];
        [sender setTitle:@"Sign in" forState:UIControlStateNormal];
    } else {
        [TDTDropboxHelper authenticateFromViewController:self completion:^(NSError *error, TDTDropboxAuthenicatedModel *authenticatedModel) {
            self.accessToken = authenticatedModel.token;
            [sender setTitle:@"Sign out" forState:UIControlStateNormal];
            NSLog(@"Authenticated with token %@", self.accessToken);
            UIAlertController *const alertController = [UIAlertController alertControllerWithTitle:@"Authenticated!" message:[NSString stringWithFormat:@"Token = %@", self.accessToken] preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
        }];
    }
}

- (IBAction)uploadButtonTapped:(id)sender
{
    NSString *filename = [NSString stringWithFormat:@"test-%lu.txt", (unsigned long)CACurrentMediaTime()];
    NSString *localPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Library/Caches/%@", filename]];
    NSString *remotePath = [NSString stringWithFormat:@"/%@", filename];
    [@"Hello World!" writeToFile:localPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    [TDTDropboxHelper uploadFileFromController:self localPath:localPath remotePath:remotePath completion:^(NSError *error, NSDictionary *parsedResponse) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                self.outputTextView.text = [error description];
            } else {
                self.outputTextView.text = [parsedResponse description];
            }
        });
    }];
}

@end
