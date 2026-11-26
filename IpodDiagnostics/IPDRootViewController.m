
#import "IPDRootViewController.h"

@implementation IPDRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Diagnostics";
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];

    UIDevice *device = [UIDevice currentDevice];
    device.batteryMonitoringEnabled = YES;

    NSProcessInfo *process = [NSProcessInfo processInfo];

    double memory = process.physicalMemory / 1048576.0;
    double uptime = process.systemUptime / 3600.0;
    float battery = device.batteryLevel * 100;

    UILabel *label = [[UILabel alloc] initWithFrame:
        CGRectMake(20, 100, 280, 300)];

    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:17];

    label.text = [NSString stringWithFormat:
        @"iPod Diagnostics\n\n"
        @"Device: %@\n"
        @"Firmware: %@\n"
        @"Memory: %.0f MB\n"
        @"Battery: %.0f%%\n"
        @"Uptime: %.2f hours\n\n"
        @"Built by Jacob",
        device.model,
        device.systemVersion,
        memory,
        battery,
        uptime
    ];

    [self.view addSubview:label];
}

@end

