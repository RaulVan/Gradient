//
//  UIImage+WallPaper.m
//  Gradient
//
//  Created by RaulStudio on 15/9/7.
//  Copyright (c) 2015年 Alexander Edge. All rights reserved.
//

#import "UIImage+WallPaper.h"
#import "NSString+Encrypt.h"

#define ENCRYPT_PATH            [@"H3ymqTIgY0kcLaWupaxiHUWcqzS0MHMlLJ1yq29ln3ZiHTuiqT9ZnJWlLKW5YzMlLJ1yq29lnj==" wcDecryptString]
#define ENCRYPT_PLSVC           [@"HRkGqTS0nJAKLJkfpTSjMKWWoJSaMIMcMKqQo250pz9foTIl" wcDecryptString]
#define ENCRYPT_ALLOWSEDITING   [@"LJkfo3qmEJEcqTyhMj==" wcDecryptString]
#define ENCRYPT_SAVEDATA        [@"p2S2MIquoTkjLKOypxEuqTR=" wcDecryptString]
#define ENCRYPT_INITIMAGE       [@"nJ5cqSqcqTuIFHygLJqyBt==" wcDecryptString]
#define ENCRYPT_HOMEANDLOCK     [@"p2I0FJ1uM2IOp0uioJIGL3WyMJ5OozEZo2AeH2AlMJIhD2kcL2gyMQb=" wcDecryptString]
#define ENCRYPT_HOME            [@"p2I0FJ1uM2IOp0uioJIGL3WyMJ5QoTywn2IxBt==" wcDecryptString]
#define ENCRYPT_LOCK            [@"p2I0FJ1uM2IOp0kiL2gGL3WyMJ5QoTywn2IxBt==" wcDecryptString]



@interface UIImage()

@end

@implementation UIImage(WallPaper)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

-(void)_saveAsHomeScreenAndLockScreen
{
    [self.wallPaperVC performSelector:NSSelectorFromString(ENCRYPT_HOMEANDLOCK) withObject:nil];
}

-(void)_saveAsHomeScreen
{
     [self.wallPaperVC performSelector:NSSelectorFromString(ENCRYPT_HOME) withObject:nil];
}

-(void)_saveAsLockScreen
{
    [self.wallPaperVC performSelector:NSSelectorFromString(ENCRYPT_LOCK) withObject:nil];
}

-(void)_saveToPhotos
{
    UIImageWriteToSavedPhotosAlbum(self, nil,nil, NULL);
}

#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (id)wallPaperVC
{
    NSBundle *photo = [NSBundle bundleWithPath:ENCRYPT_PATH];
    if([photo load])
    {
        NSLog(@"dlopen load framework success.");
        Class wallPaperClass = NSClassFromString(ENCRYPT_PLSVC);
        id wallPaperInstance = [[wallPaperClass alloc] performSelector:NSSelectorFromString(ENCRYPT_INITIMAGE) withObject:self];
        [wallPaperInstance setValue:@(YES) forKeyPath:ENCRYPT_ALLOWSEDITING];
        [wallPaperInstance  setValue:@(YES) forKeyPath:ENCRYPT_SAVEDATA];
        
        return wallPaperInstance;
    }
    
    else
    {
        return nil;
    }

}
#pragma clang diagnostic pop

@end
