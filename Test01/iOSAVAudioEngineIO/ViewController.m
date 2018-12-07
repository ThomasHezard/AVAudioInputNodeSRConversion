//
//  ViewController.m
//  iOSAVAudioEngineIO
//
//  Created by Thomas HEZARD on 05/12/2018.
//

#import "ViewController.h"
#import "AudioManager/AudioManager.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *playerPlayButton;
@property (weak, nonatomic) IBOutlet UIButton *playerPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *playerStopButton;
@property (weak, nonatomic) IBOutlet UIButton *logButton;

@property (nonatomic, strong) AudioManager* audioManager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.audioManager = [AudioManager instance];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)onLogButtonClicked:(id)sender {
    [self.audioManager log];
}

@end
