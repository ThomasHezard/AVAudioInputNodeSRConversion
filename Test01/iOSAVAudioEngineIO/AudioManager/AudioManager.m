//
//  AudioManager.m
//  iOSAVAudioEngineIO
//
//  Created by Thomas HEZARD on 05/12/2018.
//


#import "AudioManager.h"



static double DefaultSampleRate = 48000;



@interface AudioManager()

@property (nonatomic, strong)   AVAudioSession *    audioSession;
@property (nonatomic, strong)   AVAudioEngine *     audioEngine;
@property (nonatomic, strong)   AVAudioMixerNode *  mainMixer;

@property (nonatomic, strong)   AVAudioInputNode*   inputNode;

@property (nonatomic, strong)   AVAudioFile*        audioFile;

@property (nonatomic, strong)   AVAudioMixerNode*   mixer1;
@end


@implementation AudioManager


+ (AudioManager *)instance{
    static AudioManager *instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[AudioManager alloc] init];
    });
    return instance;
}


- (AVAudioFile *)audioFile {
    NSError* error = nil;
    NSURL* url = [[NSBundle mainBundle] URLForResource:@"test_track" withExtension:@"mp3"];
    AVAudioFile* file = [[AVAudioFile alloc] initForReading:url error:&error];
    return file;
}


- (AVAudioFormat*)stereoFloat32Format:(float)sampleRate {
    return [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                            sampleRate:sampleRate channels:2
                                           interleaved:NO];
}


- (void)start {

    NSError* error = nil;

    [self setupAudioSession];
    [self setupAudioEngine];
    [self registerForNotifications];

    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:&error];

    [self log];
}


- (void)setupAudioSession {

    NSError* error = nil;
    BOOL success = YES;

    self.audioSession = [AVAudioSession sharedInstance];

    /* ******* */
    AVAudioSessionCategory category         = AVAudioSessionCategoryPlayAndRecord;
    AVAudioSessionCategoryOptions options   = AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth;
    NSTimeInterval preferedBufferDuration   = 0.005;
    /* ******* */

    success = [self.audioSession setCategory:category withOptions:options error:&error];
    success = [self.audioSession setPreferredSampleRate:DefaultSampleRate error:&error];
    success = [self.audioSession setPreferredIOBufferDuration:preferedBufferDuration error:&error];
}


- (void)setupAudioEngine {

    self.audioEngine    = [[AVAudioEngine alloc] init];
    self.mainMixer      = self.audioEngine.mainMixerNode;

    /* mixer node */
    self.mixer1 = [[AVAudioMixerNode alloc] init];
    [self.audioEngine attachNode:self.mixer1];

    /* input microphone */
    self.inputNode      = self.audioEngine.inputNode;
    
    [self.audioEngine connect:self.inputNode to:self.mixer1 format:[self.inputNode inputFormatForBus:0]];
    [self.audioEngine connect:self.mixer1 to:self.mainMixer format:[self stereoFloat32Format:DefaultSampleRate]];

}


- (void)registerForNotifications {
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:self.audioSession];
    [notificationCenter addObserver:self selector:@selector(handleMediaServicesReset:) name:AVAudioSessionMediaServicesWereResetNotification object:self.audioSession];
    [notificationCenter addObserver:self selector:@selector(handleConfigurationChange:) name:AVAudioEngineConfigurationChangeNotification object:self.audioEngine];
}


- (void)unregisterNotifications {
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:AVAudioSessionInterruptionNotification object:self.audioSession];
    [notificationCenter removeObserver:self name:AVAudioSessionMediaServicesWereResetNotification object:self.audioSession];
    [notificationCenter removeObserver:self name:AVAudioEngineConfigurationChangeNotification object:self.audioEngine];
}


- (void)handleInterruption:(NSNotification *)notification {
    NSLog(@"Handle Interruption");
}


- (void)handleMediaServicesReset:(NSNotification *)notification{
    NSLog(@"Handle Media Services Reset");
}


- (void)handleConfigurationChange:(NSNotification *)notification{
    [self log];
    NSLog(@"****** Handle Configuration Changed : re-connect and restart the audio engine ******");
    AVAudioFormat * inputConnectionFormat = [self.inputNode outputFormatForBus:0];
    [self.audioEngine disconnectNodeOutput:self.inputNode];
    [self.audioEngine disconnectNodeOutput:self.mixer1];
    [self.audioEngine connect:self.inputNode to:self.mixer1 format:inputConnectionFormat];
    [self.audioEngine connect:self.mixer1 to:self.mainMixer format:[self stereoFloat32Format:DefaultSampleRate]];
    NSError *error = nil;
    [self.audioEngine startAndReturnError:&error];
    [self log];
}


- (void)logNodeFormat:(AVAudioNode*)node inputBus:(AVAudioNodeBus)inBus outputBus:(AVAudioNodeBus)outBus nodeName:(NSString*)name {

    NSString* newName = [name uppercaseString];
    printf("\n");
    printf("************ %s ************\n", newName.UTF8String);
    printf("*** INPUT %lu ***\n", (unsigned long)inBus);
    printf("Sample rate   : %.0f\n", [node inputFormatForBus:inBus].sampleRate);
    printf("Common format : %s\n", [self commonFormat:[node inputFormatForBus:inBus].commonFormat].UTF8String);
    printf("Channel count : %i\n", [node inputFormatForBus:inBus].channelCount);
    printf("*** OUTPUT %lu ***\n", (unsigned long)outBus);
    printf("Sample rate   : %.0f\n", [node outputFormatForBus:outBus].sampleRate);
    printf("Common format : %s\n", [self commonFormat:[node outputFormatForBus:outBus].commonFormat].UTF8String);
    printf("Channel count : %i\n", [node outputFormatForBus:outBus].channelCount);
}


- (void)logMixerNodeFormat:(AVAudioMixerNode*)node nodeName:(NSString*)name {

    NSString* newName = [name uppercaseString];
    NSUInteger nbBus = node.nextAvailableInputBus;
    printf("\n");
    printf("************ %s ************\n", newName.UTF8String);
    for (NSUInteger i=0; i<nbBus; ++i) {
        printf("*** INPUT %lu ***\n", (unsigned long)i);
        printf("Sample rate   : %.0f\n", [node inputFormatForBus:i].sampleRate);
        printf("Common format : %s\n", [self commonFormat:[node inputFormatForBus:i].commonFormat].UTF8String);
        printf("Channel count : %i\n", [node inputFormatForBus:i].channelCount);
    }
    printf("*** OUTPUT 0 ***\n");
    printf("Sample rate   : %.0f\n", [node outputFormatForBus:0].sampleRate);
    printf("Common format : %s\n", [self commonFormat:[node outputFormatForBus:0].commonFormat].UTF8String);
    printf("Channel count : %i\n", [node outputFormatForBus:0].channelCount);
}


- (void)logPlayerNodeFormat:(AVAudioNode*)node nodeName:(NSString*)name {

    NSString* newName = [name uppercaseString];
    printf("\n");
    printf("************ %s ************\n", newName.UTF8String);
    printf("*** OUTPUT 0 ***\n");
    printf("Sample rate   : %.0f\n", [node outputFormatForBus:0].sampleRate);
    printf("Common format : %s\n", [self commonFormat:[node outputFormatForBus:0].commonFormat].UTF8String);
    printf("Channel count : %i\n", [node outputFormatForBus:0].channelCount);
}


- (NSString*)commonFormat:(int)cf {
    NSString* stringCommonFormat;
    switch (cf) {
        case 0:
            stringCommonFormat = @"Other";
            break;
        case 1:
            stringCommonFormat = @"Float32";
            break;
        case 2:
            stringCommonFormat = @"Float64";
            break;
        case 3:
            stringCommonFormat = @"Int16";
            break;
        case 4:
            stringCommonFormat = @"Int32";
            break;
        default:
            stringCommonFormat = @"Other";
            break;
    }
    return stringCommonFormat;
}


- (void)log {
    printf("\n");
    NSLog(@"****** Audio connections status ******");
    [self logNodeFormat:self.inputNode inputBus:0 outputBus:0 nodeName:@"Input Node"];
    [self logMixerNodeFormat:self.mixer1 nodeName:@"Mixer 1"];
    [self logMixerNodeFormat:self.mainMixer nodeName:@"Main Mixer"];
    [self logNodeFormat:self.audioEngine.outputNode inputBus:0 outputBus:0 nodeName:@"Output Node"];
    printf("\n");
}


@end
