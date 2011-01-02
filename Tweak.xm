#import <SpringBoard/SBIcon.h>
#import <SpringBoard/SBIconBadge.h>
#import <SpringBoard/SBUIController.h>
#import "UIModalView.h"
#import <objc/runtime.h>
#import <SpringBoard/SBIconModel.h>


@interface SBIconModel (pfour)
- (SBIcon *)leafIconForIdentifier:(NSString *)ident;
@end
@interface SBIcon (four)
- (NSString *)leafIdentifier;
@end

static BOOL isJittering = NO;

@interface BDBadgeDelegate : NSObject {
	SBIcon *_icon;
}
+ (id)delegateWithIcon:(SBIcon *)icon;
- (id)initWithIcon:(SBIcon *)icon;
@end
@implementation BDBadgeDelegate
+ (id)delegateWithIcon:(SBIcon *)icon
{
	return [[self alloc] initWithIcon:icon];
}

- (id)initWithIcon:(SBIcon *)icon
{
	if ((self = [super init]) != nil) {
		_icon = icon;
	}
	return self;
}

-(void)modalView:(id)view didDismissWithButtonIndex:(int)buttonIndex
{
	UITextField *badgeField = [view textFieldAtIndex:0];
	switch (buttonIndex) {
		case 2:
			[_icon setBadge:[badgeField text]];
			break;
		case 1:
			[_icon setBadge:nil];
			break;
		default:
			break;
	}
	[self release];
}

@end

%hook SBIcon

-(void)setIsJittering:(BOOL)jittering
{
	isJittering = jittering;
	%orig;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	%orig;
	UITouch *touch = [touches anyObject];
	if (touch.tapCount == 2 && isJittering) {
		NSString *message = [NSString stringWithFormat:@"Set the new badge for %@. Or click cancel to cancel", [self displayName]];
		UIModalView *badgeAlert = [[UIModalView alloc] initWithTitle:@"Set New Badge" buttons:[NSArray arrayWithObjects:@"Cancel", @"Clear", @"Okay", nil] defaultButtonIndex:0 delegate:[BDBadgeDelegate delegateWithIcon:self] context:NULL];
		[badgeAlert setBodyText:message];
		[badgeAlert setNumberOfRows:1];
		[badgeAlert addTextFieldWithValue:@"" label:@"newbadgevalue"];
		UITextField *textField = [badgeAlert textFieldAtIndex:0];
		textField.placeholder = @"Badge";
		textField.clearButtonMode = UITextFieldViewModeAlways;
		textField.keyboardAppearance = UIKeyboardAppearanceAlert;
		textField.autocorrectionType = UITextAutocorrectionTypeNo;
		textField.returnKeyType = UIReturnKeyDone;
		[badgeAlert popupAlertAnimated:YES];
		[badgeAlert release];
	}
}

%end

%hook SBUIController

- (void)finishLaunching
{
	%orig;
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.zimm.badges.plist"] ?: [[NSMutableDictionary alloc] init];
	if (![prefs objectForKey:@"2.2"]) {
		UIModalView *welcomeBadge = [[UIModalView alloc] initWithTitle:@"Welcome to badges 2.2.1!" buttons:[NSArray arrayWithObjects:@"Okay", nil] defaultButtonIndex:0 delegate:nil context:NULL];
		[welcomeBadge setBodyText:@"Welcome! To set a badge on an app just tap and hold any icon to get it into a jittering mode, then triple tap whatever icon you want. This will being a popup allowing you to set the badge, or clear it! If you ever forget this is always in the Settings.app"];
		[welcomeBadge popupAlertAnimated:YES];
		[welcomeBadge release];
		[prefs setObject:@"Hi" forKey:@"2.2"];
		[prefs writeToFile:@"/var/mobile/Library/Preferences/com.zimm.badges.plist" atomically:YES];
	}
	[prefs release];
}

%end
