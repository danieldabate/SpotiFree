//
//  SpotifyController.h
//  SpotiFree
//
//  Created by Eneas on 21.12.13.
//  Copyright (c) 2013 Eneas. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SpotifyControllerDelegate <NSObject>

@optional
- (void)activeStateShouldGetUpdated:(BOOL)isActive;
- (void)silencingAdStateShouldGetUpdated:(BOOL)isSilencingAd;

@end

@interface SpotifyController : NSObject

+ (id)spotifyController;

- (void)startService;

@property (assign) id<SpotifyControllerDelegate> delegate;

@end