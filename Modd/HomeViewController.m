//
//  ViewController.m
//  Modd
//
//  Created on 11/18/15.
//  Copyright © 2015. All rights reserved.
//

#import "StaticInlines.h"

#import "AFNetworking.h"

#import "HomeViewController.h"
#import "HomeViewCell.h"
#import "PaginationView.h"
#import "ChannelViewController.h"
#import "AuthViewController.h"
#import "ChannelVO.h"

@interface HomeViewController () <AuthViewControllerDelegate, HomeViewCellDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton *composeButton;
@property (nonatomic, strong) UIImageView *tutorialImageView;
@property (nonatomic, strong) NSArray *channelNames;
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) PaginationView *paginationView;
@property (nonatomic) int selectedRow;
@end

@implementation HomeViewController
- (id)init {
	if ((self = [super init])) {
	}
	
	return (self);
}


- (void)_registerPushNotifications {
	if ([[UIApplication sharedApplication] respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
//if (![[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
		[[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
		[[UIApplication sharedApplication] registerForRemoteNotifications];
//}
		
	} else {
//		if ([[UIApplication sharedApplication] enabledRemoteNotificationTypes] == UIRemoteNotificationTypeNone)
		[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert)];
	}
}


#pragma mark - Data Calls
- (void)_retrieveChannels {
	AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://s211400.gridserver.com"]];
	[httpClient getPath:@"channels.json" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		NSArray *result = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
		
		if (error != nil) {
			NSLog(@"AFNetworking [-] %@: (%@) - Failed to parse JSON: %@", [[self class] description], [[operation request] URL], [error localizedFailureReason]);
			
			
		} else {
			NSLog(@"AFNetworking [-] %@ |[:]>> BOOT JSON [:]|>>\n%@", [[self class] description], result);
			
			_channelNames = result;
			[_tableView reloadData];
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"AFNetworking [-] %@: (%@) Failed Request - (%d) %@", [[self class] description], [[operation request] URL], (int)[operation response].statusCode, [error localizedDescription]);
	}];
}


#pragma mark - View Lifecycle
- (void)viewDidLoad {
	[super viewDidLoad];
	
	_scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
	_scrollView.backgroundColor = [UIColor colorWithRed:0.396 green:0.596 blue:0.922 alpha:1.00];
	_scrollView.backgroundColor = [UIColor colorWithRed:0.400 green:0.839 blue:0.698 alpha:1.00];
	_scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * 3.0, _scrollView.frame.size.height);
	_scrollView.contentInset = UIEdgeInsetsZero;
	_scrollView.alwaysBounceHorizontal = YES;
	_scrollView.showsHorizontalScrollIndicator = NO;
	_scrollView.showsVerticalScrollIndicator = NO;
	_scrollView.pagingEnabled = YES;
	_scrollView.delegate = self;
	[_scrollView setTag:1];
	[self.view addSubview:_scrollView];
	
	UIImageView *tutorial1ImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tutorial_01"]];
	[_scrollView addSubview:tutorial1ImageView];
	
	UIImageView *tutorial2ImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tutorial_02"]];
	tutorial2ImageView.frame = CGRectOffset(tutorial2ImageView.frame, _scrollView.frame.size.width, 0.0);
	[_scrollView addSubview:tutorial2ImageView];
	
	UIImageView *brandingImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"brandingHeader"]];
	brandingImageView.frame = CGRectOffset(brandingImageView.frame, (_scrollView.frame.size.width * 2.0) + (self.view.frame.size.width - brandingImageView.frame.size.width) * 0.5, 9.0);
	[_scrollView addSubview:brandingImageView];
	
	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(_scrollView.frame.size.width * 2.0, 54.0, _scrollView.frame.size.width, _scrollView.frame.size.height - 54.0) style:UITableViewStylePlain];
	_tableView.backgroundColor = [UIColor whiteColor];
	_tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, _composeButton.frame.size.height, 0.0);
	_tableView.delegate = self;
	_tableView.dataSource = self;
	[_tableView setTag:2];
	_tableView.alwaysBounceVertical = YES;
	_tableView.showsVerticalScrollIndicator = YES;
	[_scrollView addSubview:_tableView];
	
	_composeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_composeButton.frame = CGRectMake(0.0, _scrollView.frame.size.height, _scrollView.frame.size.width, 32.0);
	[_composeButton addTarget:self action:@selector(_goCompose) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:_composeButton];
	
	_paginationView = [[PaginationView alloc] initAtPosition:CGPointMake(_scrollView.frame.size.width * 0.5, self.view.frame.size.height - 40.0) withTotalPages:3 usingDiameter:7.0 andPadding:10.0];
	[_paginationView updateToPage:0];
	[self.view addSubview:_paginationView];
	
	_tutorialImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"createTutorial"]];
	_tutorialImageView.frame = CGRectOffset(_tutorialImageView.frame, 0.0, (_scrollView.frame.size.height + 9.0) - (_composeButton.frame.size.height + _tutorialImageView.frame.size.height));
	_tutorialImageView.hidden = YES;
	_tutorialImageView.alpha = 0.0;
	
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"home_tutorial"])
		[self.view addSubview:_tutorialImageView];
	
	[[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"home_tutorial"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[self _retrieveChannels];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	
}


#pragma mark - Navigation
- (void)_goCompose {
	_loadingView = [[UIView alloc] initWithFrame:self.view.frame];
	_loadingView.backgroundColor = [UIColor colorWithRed:0.839 green:0.729 blue:0.400 alpha:1.00];
	[self.view addSubview:_loadingView];
	
	UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	activityIndicatorView.center = CGPointMake(_loadingView.bounds.size.width * 0.5, (_loadingView.bounds.size.height + 20.0) * 0.5);
	[activityIndicatorView startAnimating];
	[_loadingView addSubview:activityIndicatorView];
}


#pragma mark - AuthViewController Delegates
- (void)authViewController:(AuthViewController *)viewController didAuthAsOwner:(NSDictionary *)twitchUser {
	NSLog(@"[*:*] authViewController:didAuthAsOwner:[%@])", twitchUser);
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
		//[self.navigationController pushViewController:[[ChannelViewController alloc] initWithChannelName:[[_channelNames objectAtIndex:_selectedRow] objectForKey:@"channel"] asTwitchUser:twitchUser] animated:YES];
		[self.navigationController pushViewController:[[ChannelViewController alloc] initWithChannel:[ChannelVO channelWithDictionary:[_channelNames objectAtIndex:_selectedRow]] asTwitchUser:twitchUser] animated:YES];
	});
}


#pragma mark - TableView DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return (1);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return ([_channelNames count]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	HomeViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
	
	if (cell == nil)
		cell = [[HomeViewCell alloc] init];
	[cell setSize:[tableView rectForRowAtIndexPath:indexPath].size];
	[cell setIndexPath:indexPath];
	cell.delegate = self;
	
	[cell populateFields:[_channelNames objectAtIndex:indexPath.row]];
	[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
	
	return (cell);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tableHeaderBG"]];
	
	//	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 4.0, tableView.frame.size.width - 30.0, 15.0)];
	//	label.font = [[[HONFontAllocator sharedInstance] avenirHeavy] fontWithSize:13];
	//	label.backgroundColor = [UIColor clearColor];
	//	label.textColor = [[HONColorAuthority sharedInstance] honGreyTextColor];
	//	label.text = (section == 0) ? @"Recent" : @"Older";
	//	[imageView addSubview:label];
	
	return (imageView);
}


#pragma mark - TableView Delegates
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return (74.0);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return (0.0);
	return ([[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tableHeaderBG"]].frame.size.height);
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return (indexPath);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
	//HONHomeViewCell *cell = (HONHomeViewCell *)[tableView cellForRowAtIndexPath:indexPath];
	
	
	//[[HONAnalyticsReporter sharedInstance] trackEvent:[kAnalyticsCohort stringByAppendingString:@" - joinPopup"] withProperties:@{@"channel"	: @"e23d61a9-622c-45c1-b92e-fd7c5d586b3a_1438284321"}];
		
	_loadingView = [[UIView alloc] initWithFrame:self.view.frame];
	_loadingView.backgroundColor = [UIColor	colorWithRed:0.839 green:0.729 blue:0.400 alpha:1.00];
	//[self.view addSubview:_loadingView];
	
	UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	activityIndicatorView.center = CGPointMake(_loadingView.bounds.size.width * 0.5, (_loadingView.bounds.size.height + 20.0) * 0.5);
	[activityIndicatorView startAnimating];
	[_loadingView addSubview:activityIndicatorView];
	
	_selectedRow = indexPath.row;
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
															 delegate:self
													cancelButtonTitle:@"Cancel"
											   destructiveButtonTitle:nil
													otherButtonTitles:@"View Channel", @"Owner Login", nil];
	[actionSheet setTag:HomeActionSheetTypeRowSelect];
	[actionSheet showInView:self.view];
}


#pragma mark - ScrollView Delegates
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	//NSLog(@"[*:*] scrollViewDidScroll:[%@](%d)", NSStringFromCGPoint(scrollView.contentOffset), scrollView.tag);
	
	if (scrollView.tag == 1) {
		if (scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.size.height || scrollView.contentOffset.y < 0.0)
			[scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, scrollView.contentSize.height - scrollView.frame.size.height)];
		
		if (scrollView.contentOffset.x < scrollView.contentSize.width - scrollView.frame.size.width) {
			if (_composeButton.frame.origin.y == scrollView.frame.size.height - _composeButton.frame.size.height) {
				[UIView animateWithDuration:0.250 delay:0.000 options:(UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationCurveEaseOut) animations:^(void) {
					_tutorialImageView.alpha = 0.0;
					
					_composeButton.alpha = 0.0;
//					_composeButton.frame = CGRectTranslateY(_composeButton.frame, scrollView.frame.size.height);
				} completion:^(BOOL finished) {
					_tutorialImageView.hidden = YES;
				}];
			}
			
			if (_paginationView.frame.origin.y == (self.view.frame.size.height - 40.0) - (_composeButton.frame.size.height + 10.0)) {
				[UIView animateWithDuration:0.250 delay:0.000 options:(UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationCurveEaseIn) animations:^(void) {
					_paginationView.frame = CGRectTranslateY(_paginationView.frame, self.view.frame.size.height - 40.0);
					_paginationView.alpha = 1.0;
				} completion:^(BOOL finished) {
				}];
			}
			
		} else if (scrollView.contentOffset.x >= scrollView.contentSize.width - scrollView.frame.size.width) {
			scrollView.scrollEnabled = NO;
		}
	}
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
	//	UIColor *color = [_colors objectAtIndex:(int)(scrollView.contentOffset.x / scrollView.frame.size.width)];
	//	[UIView animateWithDuration:0.333 animations:^(void) {
	//		[[HONViewDispensor sharedInstance] tintView:scrollView withColor:color];
	//	} completion:nil];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	//	NSLog(@"[*:*] scrollViewDidEndDecelerating:[%@]", NSStringFromCGPoint(scrollView.contentOffset));
	//	[[HONAnalyticsReporter sharedInstance] trackEvent:[NSString stringWithFormat:@"HOME - swipe_%d", (int)(scrollView.contentOffset.x / scrollView.frame.size.width)]];
	
	if (scrollView.tag == 1) {
		[_paginationView updateToPage:scrollView.contentOffset.x / scrollView.frame.size.width];
		if (scrollView.contentOffset.x >= _scrollView.contentSize.width - _scrollView.frame.size.width) {
			[self _registerPushNotifications];
			
			if ([[NSUserDefaults standardUserDefaults] objectForKey:@"subscription"] == nil) {
				[[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"subscription"];
				[[NSUserDefaults standardUserDefaults] synchronize];
			}
			
			if (_composeButton.frame.origin.y == scrollView.frame.size.height) {
				[UIView animateWithDuration:0.250 delay:0.000 options:(UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationCurveEaseIn) animations:^(void) {
					_composeButton.alpha = 1.0;
//					_composeButton.frame = CGRectTranslateY(_composeButton.frame, scrollView.frame.size.height - _composeButton.frame.size.height);
				} completion:^(BOOL finished) {
					_tutorialImageView.alpha = 0.0;
					_tutorialImageView.hidden = NO;
					[UIView animateWithDuration:0.250 delay:0.000 options:(UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationCurveEaseIn) animations:^(void) {
						_tutorialImageView.alpha = 1.0;
					} completion:^(BOOL finished) {
					}];
				}];
			}
			
			if (_paginationView.frame.origin.y == self.view.frame.size.height - 40.0) {
				[UIView animateWithDuration:0.250 delay:0.000 options:(UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationCurveEaseIn) animations:^(void) {
					_paginationView.alpha = 0.0;
					_paginationView.frame = CGRectTranslateY(_paginationView.frame, (self.view.frame.size.height - 40.0) - (_composeButton.frame.size.height + 10.0));
				} completion:^(BOOL finished) {
				}];
			}
			
		} else if (scrollView.contentOffset.x < scrollView.contentSize.width - scrollView.frame.size.width) {
		}
	}
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	//	NSLog(@"[*:*] scrollViewDidEndScrollingAnimation:[%@]", NSStringFromCGPoint(scrollView.contentOffset));
	
	
	if (scrollView.tag == 1) {
		[_paginationView updateToPage:scrollView.contentOffset.x / scrollView.frame.size.width];
		if (scrollView.contentOffset.x >= _scrollView.contentSize.width - _scrollView.frame.size.width) {
			[self _registerPushNotifications];
			
			if (_composeButton.frame.origin.y == scrollView.frame.size.height) {
				[UIView animateWithDuration:0.250 delay:0.000 options:(UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationCurveEaseIn) animations:^(void) {
					_composeButton.alpha = 1.0;
//					_composeButton.frame = CGRectTranslateY(_composeButton.frame, scrollView.frame.size.height - _composeButton.frame.size.height);
					
				} completion:^(BOOL finished) {
					_tutorialImageView.alpha = 0.0;
					_tutorialImageView.hidden = NO;
					[UIView animateWithDuration:0.250 delay:0.000 options:(UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationCurveEaseIn) animations:^(void) {
						_tutorialImageView.alpha = 1.0;
					} completion:^(BOOL finished) {
					}];
				}];
			}
			
			
			if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"terms"] length] == 0) {
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Terms of service"
																	message:@"You agree to the following terms."
																   delegate:self
														  cancelButtonTitle:@"View Terms"
														  otherButtonTitles:@"Agree", NSLocalizedString(@"alert_cancel", @"Cancel"), nil];
				[alertView setTag:HomeAlertViewTypeTermsAgreement];
				[alertView show];
			}
		}
	}
}


#pragma mark - ActionSheet Delegates
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSDictionary *channnelDict = [_channelNames objectAtIndex:_selectedRow];
	
	if (actionSheet.tag == HomeActionSheetTypeRowSelect) {
		if (buttonIndex == 0) {
			//[self.navigationController pushViewController:[[ChannelViewController alloc] initWithChannelName:[channnelDict objectForKey:@"channel"]] animated:YES];
			[self.navigationController pushViewController:[[ChannelViewController alloc] initWithChannel:[ChannelVO channelWithDictionary:channnelDict]] animated:YES];
			
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.125 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
				[_loadingView removeFromSuperview];
				[_tutorialImageView removeFromSuperview];
			});
		
		} else if (buttonIndex == 1) {
			AuthViewController *authViewController =[[AuthViewController alloc] initWithURL:@"https://api.twitch.tv/kraken/oauth2/authenticate?action=authorize&client_id=tocdw659phzca4ewk9yhm8n50rz8l4l&redirect_uri=modd%3A%2F%2Fauth%2F&response_type=token&scope=channel_read+channel_subscriptions+chat_login" title:@"Login"];
			[authViewController setTwitchName:[channnelDict objectForKey:@"title"]];
			authViewController.delegate = self;
			
			UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:authViewController];
			[navigationController setNavigationBarHidden:YES];
			[self presentViewController:navigationController animated:YES completion:nil];			
			
		}
	}
}

@end
