//
//  MMOpenInShareItem.m
//  LooseLeaf
//
//  Created by Adam Wulf on 8/9/14.
//  Copyright (c) 2014 Milestone Made, LLC. All rights reserved.
//

#import "MMOpenInShareItem.h"
#import "MMShareButton.h"
#import "MMShareManager.h"
#import "Mixpanel.h"
#import "Constants.h"
#import "NSThread+BlockAdditions.h"
#import "UIView+Debug.h"
#import "MMShareView.h"
#import "UIColor+Shadow.h"

@implementation MMOpenInShareItem{
    MMShareButton* button;
    MMShareView* sharingOptionsView;
    NSDateFormatter *dateFormatter;
}

@synthesize delegate;
@synthesize isShowingOptionsView;

-(id) init{
    if(self = [super init]){
        button = [[MMShareButton alloc] initWithFrame:CGRectMake(0,0, kWidthOfSidebarButton, kWidthOfSidebarButton)];
        button.arrowColor = [UIColor blackColor];
        button.bottomBgColor = [UIColor colorWithRed:29/255.0 green:102/255.0 blue:240/255.0 alpha:.85];
        button.topBgColor = [UIColor colorWithRed:26/255.0 green:210/255.0 blue:253/255.0 alpha:.85];
        button.shadowColor = [[UIColor whiteColor] colorWithAlphaComponent:.5];
        
        [button addTarget:self action:@selector(performShareAction) forControlEvents:UIControlEventTouchUpInside];
        
        // arbitrary size, will be resized to fit when it's added to a sidebar
        sharingOptionsView = [[MMShareView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        sharingOptionsView.delegate = self;

        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyyMMdd-HHmm"];
    }
    return self;
}

-(void) setIsShowingOptionsView:(BOOL)_isShowingOptionsView{
    isShowingOptionsView = _isShowingOptionsView;
    button.selected = isShowingOptionsView;
    [button setNeedsDisplay];

    [[MMShareManager sharedInstance] endSharing];
    [MMShareManager sharedInstance].delegate = nil;
}

-(MMSidebarButton*) button{
    return button;
}

-(void) performShareAction{
    if(!isShowingOptionsView){
        [delegate mayShare:self];
        // if a popover controller is dismissed, it
        // adds the dismissal to the main queue async
        // so we need to add our next steps /after that/
        // so we need to dispatch async too
        dispatch_async(dispatch_get_main_queue(), ^{
            sharingOptionsView.buttonWidth = self.button.bounds.size.width;
            [sharingOptionsView reset];
            
            NSDate *now = [[NSDate alloc] init];
            NSString *theDate = [dateFormatter stringFromDate:now];
            
            NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"LooseLeaf-%@.png", theDate]];
            [UIImagePNGRepresentation(self.delegate.imageToShare) writeToFile:filePath atomically:YES];
            NSURL* fileLocation = [NSURL URLWithString:[@"file://" stringByAppendingString:filePath]];
            [[MMShareManager sharedInstance] beginSharingWithURL:fileLocation];
            [MMShareManager sharedInstance].delegate = self;
        });
    }
}

// called when the menu appears and our button is about to be visible
-(void) willShow{
    // noop
}


// called when our button is no longer visible
-(void) didHide{
    // noop
}

-(BOOL) isAtAllPossible{
    return YES;
}

#pragma mark - Options Menu

// will dispaly buttons to open in any other app
-(UIView*) optionsView{
    return sharingOptionsView;
}

#pragma mark - MMShareViewDelegate

-(void) itemWasTappedInShareView{
    [[NSThread mainThread] performBlock:^{
        [delegate mayShare:self];
        [delegate didShare:self];
    }afterDelay:.3];
}

#pragma mark - MMShareManagerDelegate

-(void) allCellsWillLoad{
    [sharingOptionsView allCellsWillLoad];
}

-(void) cellLoaded:(UIView*)cell forIndexPath:(NSIndexPath*)indexPath{
    [sharingOptionsView cellLoaded:cell forIndexPath:indexPath];
}

-(void) allCellsLoaded:(NSArray*)arrayOfAllLoadedButtonIndexes{
    [sharingOptionsView allCellsLoaded:arrayOfAllLoadedButtonIndexes];
}

-(void) sharingHasEnded{
    [self didHide];
    [sharingOptionsView sharingHasEnded];
}

-(void) isSendingToApplication:(NSString *)application{
    [sharingOptionsView isSendingToApplication:application];
    
    [[[Mixpanel sharedInstance] people] increment:kMPNumberOfExports by:@(1)];
    [[Mixpanel sharedInstance] track:kMPEventExport properties:@{kMPEventExportPropDestination : @"OpenIn",
                                                                 kMPEventExportPropResult : application}];
}

@end
