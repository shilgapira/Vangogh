
#import "VGDemoViewController.h"


static NSString * const kTestURL = @"http://flickr.com/explore";


@interface VGDemoViewController () <UIWebViewDelegate>

@property (nonatomic,strong) UIWebView *webView;

@end


@implementation VGDemoViewController

- (id)init {
    if (self = [super init]) {
        self.navigationItem.title = @"Loading...";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:kTestURL]];
    [self.webView loadRequest:request];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
#if TARGET_IPHONE_SIMULATOR
    self.navigationItem.title = @"Press Cmd-Ctrl-Z to Toggle";
#else
    self.navigationItem.title = @"Shake to Toggle";
#endif
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    self.navigationItem.title = error.localizedDescription;
}

@end
