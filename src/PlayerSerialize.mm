//
//
//  Created by liaogang on 15/1/4.
//  Copyright (c) 2015年 liaogang. All rights reserved.
//

#import "PlayerSerialize.h"
#import "serialize.h"
#import "ThreadJob.h"
#import "PlayerTypeDefines.h"

const int max_path = 256;

FILE& operator<<(FILE& f,const NSTimeInterval &t)
{
    fwrite(&t, sizeof(NSTimeInterval), 1, &f);
    return f;
}

FILE& operator>>(FILE& f,NSTimeInterval& t)
{
    fread(&t, sizeof(NSTimeInterval), 1, &f);
    return f;
}


FILE& operator<<(FILE& f,const NSString *t)
{
   return f << t.UTF8String;
}


#pragma mark -




void saveTrackInfo(FILE &file , TrackInfo *info)
{
    saveString(file, info.artist);
    saveString(file, info.title);
    saveString(file, info.album);
    saveString(file, info.genre);
    saveString(file, info.year);
    saveString(file, info.path);
}

TrackInfo *loadTrackInfo(FILE &file)
{
    TrackInfo *info = [[TrackInfo alloc]init];
    info.artist = loadString(file);
    info.title= loadString(file);
    info.album= loadString(file);
    info.genre= loadString(file);
    info.year= loadString(file);
    info.path= loadString(file);
    
    return info;
}



NSString *loadString(FILE &file)
{
    char buf[256];
    file >> buf;
    return [NSString stringWithUTF8String:buf];
}

void saveString(FILE &file , NSString* value)
{
    file << value.UTF8String;
}

NSArray *loadStringArray(FILE &file)
{
    NSMutableArray *array;
    
    
    int count = -1;
    file >> count;
    
    while (count-->0) {
        [array addObject: loadString(file) ];
    } ;
    
    return array;
}

void saveStringArray( FILE &file , NSArray *array  )
{
    int count = (int)array.count;
    if (count > 0)
    {
        assert( [array.firstObject isKindOfClass:[NSString class]]);
        
        file << count;
        
        for (NSString *value in array)
        {
            saveString(file,value);
        }
        
    }
    
}


void saveTrackInfoArray( FILE &file , NSArray *array  )
{
    int count = (int)array.count;
    if (count > 0)
    {
        assert( [array.firstObject isKindOfClass:[TrackInfo class]] );
        
        file << count;
        
        for (TrackInfo *value in array)
        {
            saveTrackInfo(file,value);
        }
        
    }
    
}

NSArray *loadTrackInfoArray(FILE &file)
{
    NSMutableArray *array = [NSMutableArray array];
    
    int count = -1;
    file >> count;
    
    while (count-->0) {
        [array addObject: loadTrackInfo(file) ];
    } ;
    
    return array;
}

#pragma mark -

@implementation PlayerTrack (serialize)

-(void)saveTo:(FILE*)file
{
    *file << self.index;
    saveTrackInfo(*file, self.info);
}

-(void)loadFrom:(FILE*)file
{
    int index;
    *file >> index;
    self.index = index;
    
    TrackInfo *info = loadTrackInfo(*file);
    self.info = info;
    
}
@end



@implementation PlayerList (serialize)
-(void)saveTo:(NSString*)path
{
    FILE *file = fopen(path.UTF8String, "w");
    if (file)
    {
//        saveString(*file, self.name);
        
        *file << self.selectIndex << self.playIndex << self.topIndex;
        
        int count = (int) self.playerTrackList.count;
        *file << count;
        
        for (PlayerTrack *track in self.playerTrackList) {
            [track saveTo:file];
        }
        fclose(file);
    }
    
}


-(void)loadFrom:(NSString*)path
{
    FILE *file = fopen(path.UTF8String, "r");
    if (file)
    {
//        self.name = loadString(*file);
        int selectIndex,playIndex,topIndex;
        *file >> selectIndex >> playIndex >> topIndex;
        self.selectIndex=selectIndex;
        self.playIndex = playIndex;
        self.topIndex=topIndex;
        
        int count = 0;
        *file >> count;
        NSMutableArray *arr = [NSMutableArray array];
        while (count-- > 0) {
            PlayerTrack *track = [[PlayerTrack alloc]init:self];
            [track loadFrom:file];
            [arr addObject:track];
        }
        
        self.playerTrackList = arr;
        fclose(file);
    }
    
}
@end


@implementation PlayerlList (serialize)
-(void)save:(NSString*)applicationDirectory
{
    NSString *playlistDirectory = [applicationDirectory  stringByAppendingPathComponent: playlistDirectoryName ];
    
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:playlistDirectory isDirectory:nil];
    
    if (!isExist)
        [[NSFileManager defaultManager] createDirectoryAtPath:playlistDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSString *path = [playlistDirectory stringByAppendingPathComponent: playlistIndexFileName];
    
    FILE *file = fopen(path.UTF8String, "w");
    if (file)
    {
        *file << self.selectIndex << self.playIndex ;
        
        int count = (int) self.playerlList.count;
        *file << count;
        
        for (int i = 0; i < count; i++)
        {
            int index = i + 1;
            
            char path2[max_path];
            
            sprintf(path2,"%08d.upl",index);
            
            PlayerList *list = self.playerlList[i];
            [list saveTo: [playlistDirectory stringByAppendingPathComponent: [NSString stringWithUTF8String:path2 ]] ];
            
            *file << index << list.name;
        }
        
        fclose(file);
    }
    
    
}

-(void)load:(NSString*)applicationDirectory
{
    NSString *playlistDirectory = [applicationDirectory  stringByAppendingPathComponent: playlistDirectoryName ];
    
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:playlistDirectory isDirectory:nil];
    
    if (!isExist)
        [[NSFileManager defaultManager] createDirectoryAtPath:playlistDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    
    
    NSString *path = [playlistDirectory stringByAppendingPathComponent: playlistIndexFileName];
    
    FILE *file = fopen(path.UTF8String, "r");
    if (file)
    {
        int si,pi;
        *file >> si >> pi;
        self.selectIndex = si;
        self.playIndex = pi;
        
        // load all playlist indexs.
        int count = 0;
        *file >> count;
        
        NSMutableArray *arr = [NSMutableArray array];
        while (count-->0)
        {
            int index ;
            NSString *playlistName;
            *file >> index ;
            playlistName = loadString(*file);
            
            char path2[max_path];
            sprintf(path2,"%08d.upl",index);
            
            PlayerList *list = [[PlayerList alloc]init];
            list.name = playlistName;
            [list loadFrom:[playlistDirectory stringByAppendingPathComponent: [NSString stringWithUTF8String:path2] ]];
            [arr addObject: list];
        }
        
        self.playerlList = arr;
        
        fclose(file);
    }
}

@end





@implementation PlayerDocument (serialize)

-(bool)load
{
    NSString *appSupportDir = ApplicationSupportDirectory();
    
    FILE *file = fopen([appSupportDir  stringByAppendingPathComponent: docFileName ].UTF8String, "r");
    
    if (file)
    {
        int resumeAtReboot , trackSongsWhenPlayStarted ;
        float volume ;
        int playOrder ,playState , fontHeight ,lastFmEnabled ;
        NSTimeInterval playTime;
        
        *file >> resumeAtReboot  >> trackSongsWhenPlayStarted >> volume >> playOrder >>playState >> fontHeight >> lastFmEnabled >> playTime;
        
        self.resumeAtReboot=resumeAtReboot;
        self.trackSongsWhenPlayStarted = trackSongsWhenPlayStarted;
        self.volume=volume;
        self.playOrder=playOrder;
        self.playState=playState;
        self.fontHeight=fontHeight;
        self.lastFmEnabled = lastFmEnabled;
        self.playTime = playTime;
        
        
        assert(self.playerlList);
        [self.playerlList load:appSupportDir];
        
        
        fclose(file);
        
        return true;
    }
    
    return false;
}

-(bool)save
{
    NSString *appSupportDir = ApplicationSupportDirectory();
    FILE *file = fopen([appSupportDir stringByAppendingPathComponent: docFileName].UTF8String, "w");
    
    if (file)
    {
        *file << self.resumeAtReboot << self.trackSongsWhenPlayStarted  << self.volume << self.playOrder << self.playState << self.fontHeight << self.lastFmEnabled <<self.playTime ;
        
        [self.playerlList save:appSupportDir];
        
        fclose(file);
        return true;
    }
    
    return false;
}

@end

#pragma mark -

@implementation PlayerLayout (serialize)
-(bool)save
{
    FILE *file = fopen([ApplicationSupportDirectory() stringByAppendingPathComponent: layoutFileName].UTF8String, "w");
    
    if (file)
    {
        
        fclose(file);
        return true;
    }
    
    return false;
}

-(bool)load
{
    FILE *file = fopen([ApplicationSupportDirectory()  stringByAppendingPathComponent: layoutFileName ].UTF8String, "r");
    
    if (file)
    {

        
        
        fclose(file);
        
        return true;
    }
    
    return false;
}
@end
