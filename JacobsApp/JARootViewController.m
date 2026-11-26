
#import "JARootViewController.h"

@implementation JARootViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];

    UILabel *message = [[UILabel alloc] initWithFrame:
        CGRectInset(self.view.bounds, 20, 20)];

    message.text = @"I love you Wolf.\n"
                   @"\n"
                   @"- Jacob";

    message.textColor = [UIColor whiteColor];
    message.font = [UIFont boldSystemFontOfSize:28];
    message.textAlignment = NSTextAlignmentCenter;
    message.numberOfLines = 0;

    message.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                               UIViewAutoresizingFlexibleHeight;

    message.alpha = 0.0;

    [self.view addSubview:message];

    [UIView animateWithDuration:5.0
                          delay:2.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        message.alpha = 1.0;
    } completion:nil];
}

@end
