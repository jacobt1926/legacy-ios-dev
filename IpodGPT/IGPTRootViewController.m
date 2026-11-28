
#import "IGPTRootViewController.h"
#import <QuartzCore/QuartzCore.h>

#if __has_include("IPGSecrets.h")
#import "IPGSecrets.h"
#else
#define IPODGPT_TOKEN @""
#endif

// MARK: Configuration

static NSString * const API_URL =
    @"https://ipodgpt-api-orcin.vercel.app/api/chat";

static UIColor *Hex(NSUInteger hex) {
    return [UIColor colorWithRed:((hex >> 16) & 255) / 255.0
                           green:((hex >> 8) & 255) / 255.0
                            blue:(hex & 255) / 255.0
                           alpha:1.0];
}

// MARK: Gradient view

@interface PGGradientView : UIView


@end

@implementation PGGradientView

+ (Class)layerClass {
    return [CAGradientLayer class];
}

@end

// MARK: View controller

@interface IGPTRootViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UIScrollView *chatScroll;
@property (nonatomic, strong) UIStackView *chatStack;
@property (nonatomic, strong) UITextField *promptField;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *resetChatButton;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) NSLayoutConstraint *composerBottom;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *history;

@property (nonatomic, strong) NSString *apiToken;
@property (nonatomic, assign) BOOL isThinking;

@end

@implementation IGPTRootViewController
- (void)loadView {
    self.view = [[UIView alloc]
        initWithFrame:[UIScreen mainScreen].bounds];

    self.view.autoresizingMask =
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;
}

// MARK: Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	self.automaticallyAdjustsScrollViewInsets = NO;

    self.apiToken = IPODGPT_TOKEN;
    self.view.backgroundColor = Hex(0xDCE3EB);

    [self setupInterface];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(keyboardChanged:)
               name:UIKeyboardWillChangeFrameNotification
             object:nil];

    [self newChat];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController
        setNavigationBarHidden:YES animated:NO];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// MARK: Styling helpers

- (void)applyGradient:(PGGradientView *)view
                  top:(UIColor *)top
               bottom:(UIColor *)bottom {

    CAGradientLayer *gradient = (CAGradientLayer *)view.layer;

    gradient.colors = @[
        (id)top.CGColor,
        (id)bottom.CGColor
    ];
}

- (UIColor *)chatBackground {
    UIGraphicsBeginImageContextWithOptions(
        CGSizeMake(6, 6), YES, 0);

    [Hex(0xDCE3EB) setFill];
    UIRectFill(CGRectMake(0, 0, 6, 6));

    [Hex(0xD4DCE5) setFill];
    UIRectFill(CGRectMake(0, 0, 1, 6));

    UIImage *image =
        UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return [UIColor colorWithPatternImage:image];
}

// MARK: Interface

- (void)setupInterface {

    // Navigation header

    PGGradientView *header = [[PGGradientView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints = NO;

    [self applyGradient:header
                    top:Hex(0xA8BED6)
                 bottom:Hex(0x425D80)];

    [self.view addSubview:header];

    UILabel *title = [[UILabel alloc] init];
    title.text = @"iPodGPT";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:21];
    title.translatesAutoresizingMaskIntoConstraints = NO;

    title.shadowColor = Hex(0x415573);
    title.shadowOffset = CGSizeMake(0, 1);

    [header addSubview:title];

    self.resetChatButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.resetChatButton setTitle:@"New" forState:UIControlStateNormal];
    [self.resetChatButton setTitleColor:[UIColor whiteColor]
                        forState:UIControlStateNormal];

    self.resetChatButton.backgroundColor = Hex(0x58779E);
    self.resetChatButton.layer.cornerRadius = 5;
    self.resetChatButton.layer.borderWidth = 1;
    self.resetChatButton.layer.borderColor = Hex(0x3C5271).CGColor;
    self.resetChatButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    self.resetChatButton.translatesAutoresizingMaskIntoConstraints = NO;

    [self.resetChatButton addTarget:self
                       action:@selector(newChat)
             forControlEvents:UIControlEventTouchUpInside];

    [header addSubview:self.resetChatButton];

    // Connection and thinking status

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = @"Ready";
    self.statusLabel.font = [UIFont boldSystemFontOfSize:11];
    self.statusLabel.textColor = Hex(0x697A90);
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.statusLabel];

    // Scrollable conversation

    self.chatScroll = [[UIScrollView alloc] init];
    self.chatScroll.backgroundColor = [self chatBackground];
    self.chatScroll.alwaysBounceVertical = YES;
    self.chatScroll.keyboardDismissMode =
        UIScrollViewKeyboardDismissModeInteractive;

    self.chatScroll.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.chatScroll];

    self.chatStack = [[UIStackView alloc] init];
    self.chatStack.axis = UILayoutConstraintAxisVertical;
    self.chatStack.alignment = UIStackViewAlignmentFill;
    self.chatStack.spacing = 14;
    self.chatStack.translatesAutoresizingMaskIntoConstraints = NO;

    [self.chatScroll addSubview:self.chatStack];

    // Bottom composer

    PGGradientView *composer = [[PGGradientView alloc] init];
    composer.translatesAutoresizingMaskIntoConstraints = NO;

    [self applyGradient:composer
                    top:Hex(0xCBD3DF)
                 bottom:Hex(0x9CAABB)];

    [self.view addSubview:composer];

    self.promptField = [[UITextField alloc] init];
    self.promptField.placeholder = @"Ask anything...";
    self.promptField.borderStyle = UITextBorderStyleRoundedRect;
    self.promptField.backgroundColor = [UIColor whiteColor];
    self.promptField.font = [UIFont systemFontOfSize:15];
    self.promptField.returnKeyType = UIReturnKeySend;
    self.promptField.delegate = self;
    self.promptField.translatesAutoresizingMaskIntoConstraints = NO;

    [composer addSubview:self.promptField];

    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];

    [self.sendButton setTitle:@"Send"
                     forState:UIControlStateNormal];

    [self.sendButton setTitleColor:[UIColor whiteColor]
                          forState:UIControlStateNormal];

    self.sendButton.titleLabel.font =
        [UIFont boldSystemFontOfSize:14];

    self.sendButton.backgroundColor = Hex(0x397FC5);
    self.sendButton.layer.cornerRadius = 14;
    self.sendButton.layer.borderWidth = 1;
    self.sendButton.layer.borderColor = Hex(0x28588D).CGColor;

    self.sendButton.translatesAutoresizingMaskIntoConstraints = NO;

    [self.sendButton addTarget:self
                        action:@selector(sendMessage)
              forControlEvents:UIControlEventTouchUpInside];

    [composer addSubview:self.sendButton];

    self.composerBottom =
        [composer.bottomAnchor
            constraintEqualToAnchor:self.view.bottomAnchor];

    // Layout constraints

    [NSLayoutConstraint activateConstraints:@[

        [header.topAnchor constraintEqualToAnchor:
            self.topLayoutGuide.bottomAnchor],

        [header.leadingAnchor constraintEqualToAnchor:
            self.view.leadingAnchor],

        [header.trailingAnchor constraintEqualToAnchor:
            self.view.trailingAnchor],

        [header.heightAnchor constraintEqualToConstant:46],

        [title.centerXAnchor constraintEqualToAnchor:
            header.centerXAnchor],

        [title.centerYAnchor constraintEqualToAnchor:
            header.centerYAnchor],

        [self.resetChatButton.trailingAnchor constraintEqualToAnchor:
            header.trailingAnchor constant:-8],

        [self.resetChatButton.centerYAnchor constraintEqualToAnchor:
            header.centerYAnchor],

        [self.resetChatButton.widthAnchor constraintEqualToConstant:48],
        [self.resetChatButton.heightAnchor constraintEqualToConstant:29],

        [self.statusLabel.topAnchor constraintEqualToAnchor:
            header.bottomAnchor],

        [self.statusLabel.leadingAnchor constraintEqualToAnchor:
            self.view.leadingAnchor],

        [self.statusLabel.trailingAnchor constraintEqualToAnchor:
            self.view.trailingAnchor],

        [self.statusLabel.heightAnchor constraintEqualToConstant:28],

        [self.chatScroll.topAnchor constraintEqualToAnchor:
            self.statusLabel.bottomAnchor],

        [self.chatScroll.leadingAnchor constraintEqualToAnchor:
            self.view.leadingAnchor],

        [self.chatScroll.trailingAnchor constraintEqualToAnchor:
            self.view.trailingAnchor],

        [self.chatScroll.bottomAnchor constraintEqualToAnchor:
            composer.topAnchor],

        [self.chatStack.topAnchor constraintEqualToAnchor:
            self.chatScroll.topAnchor constant:12],

        [self.chatStack.leadingAnchor constraintEqualToAnchor:
            self.chatScroll.leadingAnchor constant:12],

        [self.chatStack.trailingAnchor constraintEqualToAnchor:
            self.chatScroll.trailingAnchor constant:-12],

        [self.chatStack.bottomAnchor constraintEqualToAnchor:
            self.chatScroll.bottomAnchor constant:-12],

        [self.chatStack.widthAnchor constraintEqualToAnchor:
            self.chatScroll.widthAnchor constant:-24],

        [composer.leadingAnchor constraintEqualToAnchor:
            self.view.leadingAnchor],

        [composer.trailingAnchor constraintEqualToAnchor:
            self.view.trailingAnchor],

        [composer.heightAnchor constraintEqualToConstant:50],

        self.composerBottom,

        [self.promptField.leadingAnchor constraintEqualToAnchor:
            composer.leadingAnchor constant:8],

        [self.promptField.centerYAnchor constraintEqualToAnchor:
            composer.centerYAnchor],

        [self.promptField.heightAnchor constraintEqualToConstant:33],

        [self.promptField.trailingAnchor constraintEqualToAnchor:
            self.sendButton.leadingAnchor constant:-8],

        [self.sendButton.trailingAnchor constraintEqualToAnchor:
            composer.trailingAnchor constant:-8],

        [self.sendButton.centerYAnchor constraintEqualToAnchor:
            composer.centerYAnchor],

        [self.sendButton.widthAnchor constraintEqualToConstant:60],
        [self.sendButton.heightAnchor constraintEqualToConstant:32]
    ]];
}

// MARK: Chat bubbles

- (void)addMessage:(NSString *)message outgoing:(BOOL)outgoing {

    UIView *row = [[UIView alloc] init];

    PGGradientView *bubble = [[PGGradientView alloc] init];
    bubble.translatesAutoresizingMaskIntoConstraints = NO;
    bubble.layer.cornerRadius = 13;
    bubble.layer.borderWidth = 1;
    bubble.layer.masksToBounds = YES;

    if (outgoing) {
        [self applyGradient:bubble
                        top:Hex(0xDCF3B9)
                     bottom:Hex(0x9ACB65)];

        bubble.layer.borderColor = Hex(0x90B46B).CGColor;
    } else {
        [self applyGradient:bubble
                        top:Hex(0xFFFFFF)
                     bottom:Hex(0xE9EDF2)];

        bubble.layer.borderColor = Hex(0xAEB9C6).CGColor;
    }

    UILabel *label = [[UILabel alloc] init];
    label.text = message;
    label.font = [UIFont systemFontOfSize:16];
    label.textColor = Hex(0x263140);
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.translatesAutoresizingMaskIntoConstraints = NO;

    CGFloat maxWidth = 258;

    CGSize measured = [label sizeThatFits:
        CGSizeMake(maxWidth - 24, CGFLOAT_MAX)];

    CGFloat width = MIN(maxWidth, MAX(50, ceil(measured.width) + 24));

    label.preferredMaxLayoutWidth = width - 24;

    [bubble addSubview:label];
    [row addSubview:bubble];

    [NSLayoutConstraint activateConstraints:@[

        [bubble.topAnchor constraintEqualToAnchor:row.topAnchor],
        [bubble.bottomAnchor constraintEqualToAnchor:row.bottomAnchor],

        [bubble.widthAnchor constraintEqualToConstant:width],

        [label.topAnchor constraintEqualToAnchor:
            bubble.topAnchor constant:10],

        [label.bottomAnchor constraintEqualToAnchor:
            bubble.bottomAnchor constant:-10],

        [label.leadingAnchor constraintEqualToAnchor:
            bubble.leadingAnchor constant:12],

        [label.trailingAnchor constraintEqualToAnchor:
            bubble.trailingAnchor constant:-12]
    ]];

    if (outgoing) {
        [bubble.trailingAnchor
            constraintEqualToAnchor:row.trailingAnchor].active = YES;
    } else {
        [bubble.leadingAnchor
            constraintEqualToAnchor:row.leadingAnchor].active = YES;
    }

    [self.chatStack addArrangedSubview:row];

    [self scrollToBottom];
}

- (void)scrollToBottom {
    [self.view layoutIfNeeded];

    CGFloat bottom = MAX(
        0,
        self.chatScroll.contentSize.height -
        self.chatScroll.bounds.size.height
    );

    [self.chatScroll setContentOffset:CGPointMake(0, bottom)
                             animated:YES];
}

// MARK: Conversation

- (void)newChat {

    if (self.isThinking) return;

	self.history = [[NSMutableArray alloc] init];

    for (UIView *row in [self.chatStack.arrangedSubviews copy]) {
        [self.chatStack removeArrangedSubview:row];
        [row removeFromSuperview];
    }

    self.statusLabel.text = @"iPodGPT - Ready";
    self.promptField.text = @"";

    [self addMessage:
        @"Welcome to iPodGPT.\n\n"
        @"Modern intelligence. Classic hardware.\n\n"
        @"What can I help you with?"
        outgoing:NO];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendMessage];
    return YES;
}

- (void)sendMessage {

    if (self.isThinking) return;

    NSString *message = [self.promptField.text
        stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (message.length == 0) return;

    if (self.apiToken.length == 0) {
        self.statusLabel.text = @"Missing private token";
        return;
    }

    if (message.length > 4000) {
        self.statusLabel.text = @"Message too long";
        return;
    }

    self.promptField.text = @"";
    [self.promptField resignFirstResponder];

    [self addMessage:message outgoing:YES];
    [self requestAI:message];
}

// MARK: Networking

- (void)requestAI:(NSString *)message {

    self.isThinking = YES;
    self.sendButton.enabled = NO;
    self.resetChatButton.enabled = NO;
    self.sendButton.alpha = 0.5;

    self.statusLabel.text = @"iPodGPT is thinking...";

    NSURL *url = [NSURL URLWithString:API_URL];

    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"POST";
    request.timeoutInterval = 60.0;

    [request setValue:@"application/json"
        forHTTPHeaderField:@"Content-Type"];

    [request setValue:
        [NSString stringWithFormat:@"Bearer %@", self.apiToken]
        forHTTPHeaderField:@"Authorization"];

    NSDictionary *body = @{
    @"message": message,
    @"history": self.history
	};

	request.HTTPBody =
    [NSJSONSerialization dataWithJSONObject:body
                                    options:0
                                      error:NULL];

    NSURLSessionDataTask *task =
        [[NSURLSession sharedSession]
            dataTaskWithRequest:request
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {

        dispatch_async(dispatch_get_main_queue(), ^{

            self.isThinking = NO;
            self.sendButton.enabled = YES;
            self.resetChatButton.enabled = YES;
            self.sendButton.alpha = 1.0;
            self.statusLabel.text = @"iPodGPT - Ready";

            if (error) {
                [self addMessage:
                    error.localizedDescription outgoing:NO];
                return;
            }

            NSHTTPURLResponse *http =
                (NSHTTPURLResponse *)response;

            if (http.statusCode == 401) {
                [self addMessage:
                    @"Authentication failed. Check your private token."
                    outgoing:NO];
                return;
            }

            id json = data ?
                [NSJSONSerialization JSONObjectWithData:data
                    options:0 error:NULL] : nil;

            if ([json isKindOfClass:[NSDictionary class]]) {

                id reply = json[@"reply"];

                if ([reply isKindOfClass:[NSString class]]
                    && [reply length] > 0) {

                    [self.history addObject:@{
    					@"role": @"user",
    					@"content": message
					}];

					[self.history addObject:@{
						@"role": @"assistant",
						@"content": reply
					}];

					// Limit context to the last 10 exchanges.
					while (self.history.count > 20) {
						[self.history removeObjectsInRange:NSMakeRange(0, 2)];
					}

					[self addMessage:reply outgoing:NO];

                } else {

                    id apiError = json[@"error"];

                    [self addMessage:
                        [apiError isKindOfClass:[NSString class]]
                            ? apiError
                            : @"Unexpected server response."
                        outgoing:NO];
                }

            } else {
                [self addMessage:
                    [NSString stringWithFormat:@"Server error: %ld",
                        (long)http.statusCode]
                    outgoing:NO];
            }
        });
    }];

    [task resume];
}

// MARK: Keyboard handling

- (void)keyboardChanged:(NSNotification *)notification {

    NSDictionary *info = notification.userInfo;

    CGRect frame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];

    frame = [self.view convertRect:frame fromView:nil];

    CGRect intersection = CGRectIntersection(self.view.bounds, frame);

    CGFloat overlap = CGRectIsNull(intersection)
        ? 0 : CGRectGetHeight(intersection);

    self.composerBottom.constant = -overlap;

    double duration =
        [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    NSUInteger curve =
        [info[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];

    [UIView animateWithDuration:duration
                          delay:0
                        options:(UIViewAnimationOptions)(curve << 16)
                     animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self scrollToBottom];
    }];
}

@end
