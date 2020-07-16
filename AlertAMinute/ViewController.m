//
//  ViewController.m
//  AlertAMinute
//
//  Created by Han Mingjie on 2020/7/9.
//  Copyright © 2020 MingJie Han. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#define USER_SECONDS_KEY @"USER_SECONDS"
@interface ViewController (){
    UILabel *label;
    AVPlayer *player;
    CAShapeLayer *progressLayer;
    CAShapeLayer *outLaye;
    UIColor *recording_color;
    float round_seconds;
    float completed_seconds;
    NSTimer *timer;
    
    UIButton *reset_button;
}

@end

@implementation ViewController

-(void)input_seconds{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Seconds" message:@"How Many seconds your want to alert?" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"60";
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
        float target = [alert.textFields.firstObject.text floatValue];
        [user setValue:[NSNumber numberWithFloat:target] forKey:USER_SECONDS_KEY];
        [user synchronize];
        self->round_seconds = target;
    }];
    [alert addAction:action];
    UIAlertAction *cancel_action = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel_action];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(input_seconds)];
    self.title = @"Alert A Minute";
    round_seconds = [[[NSUserDefaults standardUserDefaults] valueForKey:USER_SECONDS_KEY] floatValue];
    if (0 == round_seconds){
        round_seconds = 5.f;
    }
    recording_color = [UIColor colorWithRed:70.f/255.f green:136.f/255.f blue:241.f/255.f alpha:1.f];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (nil == progressLayer){
        float button_width = 60.f;
        if ([[UIDevice currentDevice].model isEqualToString:@"iPad"]){
            button_width = self.view.frame.size.width/3.f;
        }
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:self.view.center radius:button_width/2.f+30.f startAngle:-0.5 * M_PI  endAngle:1.5*M_PI clockwise:YES];
        outLaye = [CAShapeLayer layer];
        outLaye.strokeColor = [UIColor colorWithRed:0.56 green:0.56 blue:0.56 alpha:0.5].CGColor;
        outLaye.lineWidth = 4;
        outLaye.fillColor =  [UIColor clearColor].CGColor;
        outLaye.path = path.CGPath;
        [self.view.layer addSublayer:outLaye];
        
        progressLayer = [CAShapeLayer layer];
        progressLayer.fillColor = [UIColor clearColor].CGColor;
        progressLayer.strokeColor = recording_color.CGColor;
        progressLayer.lineWidth = 8;
        progressLayer.lineCap = kCALineCapRound;
        progressLayer.path = path.CGPath;
        progressLayer.strokeStart = 0.f;
        progressLayer.strokeEnd = 0.f;
        [self.view.layer addSublayer:progressLayer];
    }
    if (nil == label){
        label = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f,self.view.frame.size.width,80.f)];
        label.textColor = [UIColor systemPinkColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:32.f];
        if ([[UIDevice currentDevice].model isEqualToString:@"iPad"]){
            label.font = [UIFont boldSystemFontOfSize:72.f];
        }
        label.center = self.view.center;
        [self.view addSubview:label];
    }
    
    if (nil == reset_button){
        float width = self.view.frame.size.width/3.f;
        reset_button = [[UIButton alloc] init];
        [reset_button setFrame:CGRectMake(width, self.view.frame.size.height-100.f, width, 60.f)];
        if ([[UIDevice currentDevice].model isEqualToString:@"iPad"]){
            
        }else{
            
        }
        reset_button.layer.masksToBounds = YES;
        reset_button.layer.cornerRadius = 8.f;
        reset_button.backgroundColor = [UIColor grayColor];
        reset_button.titleLabel.text = @"Reset";
        reset_button.titleLabel.textColor = [UIColor whiteColor];
        [reset_button setTitle:@"Reset" forState:UIControlStateNormal];
        reset_button.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
        [reset_button addTarget:self action:@selector(reset) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:reset_button];
    }
    [self start];
}

-(void)reset{
    completed_seconds = 0.f;
    label.text = [NSString stringWithFormat:@"%.1f",round_seconds-completed_seconds];
    [self updateProgressWithNumber:completed_seconds];
}

-(void)play_sound{
    if (nil == player){
        NSString *path = [[NSBundle mainBundle] pathForResource:@"abc" ofType:@"wav"];
        player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:path]];
    }
    [player seekToTime:CMTimeMake(0, 1.f)];
    [player play];
}

-(void)stop{
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(start)];
    [timer invalidate];
    timer = nil;
    [self updateProgressWithNumber:0.f];
}

-(void)start{
    completed_seconds = 0.f;
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        self->completed_seconds += 0.1;
        if (self->completed_seconds >= self->round_seconds){
            [self play_sound];
            self->completed_seconds = 0.f;
            self->progressLayer.strokeColor = [UIColor colorWithRed:((float)(random()%255))/255.f green:((float)(random()%255))/255.f blue:((float)(random()%255))/255.f alpha:1.f].CGColor;
        }
        self->label.text = [NSString stringWithFormat:@"%.1f",self->round_seconds-self->completed_seconds];
        [self updateProgressWithNumber:self->completed_seconds];
    }];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(stop)];
}

- (void)updateProgressWithNumber:(float)number {
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [CATransaction setAnimationDuration:0.1];
    progressLayer.strokeEnd =  number / round_seconds;
    [CATransaction commit];
}

@end
