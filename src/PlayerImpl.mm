//
//  UPlayer.m
//  uPlayer
//
//  Created by liaogang on 15/1/27.
//  Copyright (c) 2015年 liaogang. All rights reserved.
//

#import "PlayerTrack.h"
#import "audioTag.h"

#import "fileCtrl.h"
#import "threadpool.h"

#import "UPlayer.h"
#import "PlayerMessage.h"

TrackInfo* getId3Info(NSString *filename)
{
    TrackInfo* at = [[TrackInfo alloc]init];
    char artist[256];
    char title[256];
    char album[256];
    char genre[256];
    char year[256];
    
    if( getId3Info(filename.UTF8String, artist, title, album,genre,year) )
    {
        at.artist=[NSString stringWithUTF8String:artist];
        at.title=[NSString stringWithUTF8String:title];
        at.album=[NSString stringWithUTF8String:album];
        at.genre=[NSString stringWithUTF8String:genre];
        
        if([at.genre isEqualToString:@"null"])
            at.genre=@"";
        
        at.year=[NSString stringWithUTF8String:year];
        
        return at;
    }
    
    return nil;
}



void* addJobIsFileAudio(const char * file ,void *arg)
{
    NSMutableArray *array = (__bridge NSMutableArray*)arg;
    
    TrackInfo *arti = getId3Info([NSString stringWithUTF8String:file]);
    
    if (arti) {
        arti.path = [NSString stringWithUTF8String:file];
        
        [array addObject:arti];
    }
    
    return nil;
}


NSArray* enumAudioFiles(NSString* path)
{
    NSMutableArray *array = [NSMutableArray array];
    
    pool_init(8);
    
    IterFiles(std::string (path.UTF8String ), std::string (path.UTF8String ), addJobIsFileAudio, (__bridge void*)array );
    
    pool_destroy();
    
    return array;
}



void playTrack(TrackInfo *track)
{
    static int playUuid = -1;
    
    PlayerEngine *e =player().engine;
    
    if (playUuid == [track uuid])
    {

        [player().engine playPause];
        if ([e isPlaying])
            postEvent(EventID_track_resumed, track.title);
        else
            postEvent(EventID_track_paused, track.title);
        
    }
    else
    {
        [e playURL: [NSURL fileURLWithPath:track.path]];
        postEvent(EventID_to_change_player_title, track.title);
    }
    
}

void playTrack(PlayerList *list,PlayerTrack *track)
{
#ifdef DEBUG
    
#endif
    
    if (track)
    {
        playTrack(track.info);
        postEvent(EventID_track_started, nil);
    }
    
    PlayerlList *llist = player().document.playerlList;
    llist.playIndex = (int) [llist.playerlList indexOfObject:list];
    list.playIndex = (int) [list.playerTrackList indexOfObject:track];
    
}

