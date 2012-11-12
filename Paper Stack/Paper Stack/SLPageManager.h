//
//  SLPageManager.h
//  scratchpaper
//
//  Created by Adam Wulf on 11/12/12.
//
//

#import <Foundation/Foundation.h>
#import "SLPaperStackView.h"

@interface SLPageManager : NSObject{
    //
    // this is the stack of pages
    // that we need to save
    //
    // anything in the bezelStackHolder
    // (used for animation)
    // will be assumed to be hidden
    SLPaperStackView* stackView;
    CGRect idealBounds;
    
    
    // Debug
    NSTimer* timer;
}

@property (nonatomic, assign) SLPaperStackView* stackView;
@property (nonatomic, assign) CGRect idealBounds;

+(SLPageManager*) sharedInstace;

-(void) load;
-(void) save;

@end
