//
//  SpotifyController.m
//  SpotiFree
//
//  Created by Eneas on 21.12.13.
//  Copyright (c) 2013 Eneas. All rights reserved.
//

#import "SpotifyController.h"
#import "Spotify.h"
#import "AppData.h"

#define SPOTIFY_BUNDLE_IDENTIFIER @"com.spotify.client"

#define IDLE_TIME 0.3
#define TIMER_CHECK_AD [NSTimer scheduledTimerWithTimeInterval:IDLE_TIME target:self selector:@selector(checkForAd) userInfo:nil repeats:YES]
#define TIMER_CHECK_MUSIC [NSTimer scheduledTimerWithTimeInterval:IDLE_TIME target:self selector:@selector(checkForMusic) userInfo:nil repeats:YES]

@interface SpotifyController () {
    NSInteger _currentVolume;
}

@property (strong) SpotifyApplication *spotify;
@property (strong) AppData *appData;
@property (strong) NSTimer *timer;

@property (assign) BOOL shouldRun;

@end

@implementation SpotifyController

#pragma mark -
#pragma mark Initialisation
+ (id)spotifyController {
    return [[self alloc] init];
}

- (id)init
{
    self = [super init];
    if (self) {
        self.spotify = [SBApplication applicationWithBundleIdentifier:SPOTIFY_BUNDLE_IDENTIFIER];
        self.appData = [AppData sharedData];
        
        self.shouldRun = YES;
        [self addObserver:self forKeyPath:@"shouldRun" options:NSKeyValueObservingOptionOld context:nil];
        
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateChanged) name:@"com.spotify.client.PlaybackStateChanged" object:nil];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"shouldRun"]) {
        if (self.shouldRun) {
            if (self.timer)
                [self.timer invalidate];
            self.timer = TIMER_CHECK_AD;
        } else {
            if (self.timer)
                [self.timer invalidate];
        }
        if ([self.delegate respondsToSelector:@selector(activeStateShouldGetUpdated:)])
            [self.delegate activeStateShouldGetUpdated:self.shouldRun];
    }
}

- (void)playbackStateChanged {
    if (self.shouldRun && ![self isPlaying]) {
        self.shouldRun = NO;
    } else if ((!self.shouldRun) && [self isPlaying]) {
        self.shouldRun = YES;
    }
}

#pragma mark -
#pragma mark Public Methods
- (void)startService {
    [self playbackStateChanged];
    
    if (self.shouldRun)
        self.timer = TIMER_CHECK_AD;
}

#pragma mark -
#pragma mark Timer Methods
- (void)checkForAd {
    if ([self isAnAd]) {
        [self.timer invalidate];
        [self mute];
        self.timer = TIMER_CHECK_MUSIC;
    }
}

- (void)checkForMusic {
    if (![self isAnAd]) {
        [self.timer invalidate];
        [self unmute];
        if (self.shouldRun)
            self.timer = TIMER_CHECK_AD;
    }
}

#pragma mark -
#pragma mark Player Control Methods
- (void)mute {
    _currentVolume = self.spotify.soundVolume;
    [self.spotify pause];
    [self.spotify setSoundVolume:0];
    [self.spotify play];
    
    if ([self.delegate respondsToSelector:@selector(activeStateShouldGetUpdated:)])
        [self.delegate silencingAdStateShouldGetUpdated:YES];
}

- (void)unmute {
    double delayInSeconds = 0.8;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.spotify setSoundVolume:_currentVolume];
        
        if ([self.delegate respondsToSelector:@selector(activeStateShouldGetUpdated:)])
            [self.delegate silencingAdStateShouldGetUpdated:NO];
    });
}

- (BOOL)isAnAd {
    NSInteger currentTrackNumber = self.spotify.currentTrack.trackNumber;
    NSString * currentTrackUrl = self.spotify.currentTrack.spotifyUrl;
    
    return currentTrackNumber == 0 && [currentTrackUrl hasPrefix:@"spotify:track"];
}

- (BOOL)isPlaying {
    return [self isRunning] && self.spotify.playerState == SpotifyEPlSPlaying;
}

- (BOOL)isRunning {
    return self.spotify.isRunning;
}

- (void)dealloc {
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:@"shouldRun"];
}

@end
