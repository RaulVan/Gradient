//
//  UIImage+WallPaper.h
//  Gradient
//
//  Created by RaulStudio on 15/9/7.
//  Copyright (c) 2015年 Alexander Edge. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIImage(WallPaper)

- (void)_saveAsHomeScreenAndLockScreen;
- (void)_saveAsHomeScreen;
- (void)_saveAsLockScreen;
- (void)_saveToPhotos;

@end
