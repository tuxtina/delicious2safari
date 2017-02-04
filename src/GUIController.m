//
//  GUIController.m
//  delicious2safari
//
//  Created by Christina Zeeh on 2004-09-18.
//  Copyright (C) 2004 Christina Zeeh
//  
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//  
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//

#include <Security/SecKeychain.h>
#include <Security/SecKeychainItem.h>
#include <Security/SecAccess.h>
#include <Security/SecTrustedApplication.h>
#include <Security/SecACL.h>

#import "GUIController.h"
#import "DeliciousToSafari.h"
#import "GenericSheetController.h"
#import "InfoSheetController.h"

// user defaults keys
NSString *D2SLogin = @"D2SLogin";
NSString *D2SPasswordAsk = @"D2SPasswordAsk";
NSString *D2SReplace = @"D2SReplace";
NSString *D2SOrganize = @"D2SOrganize";
NSString *D2SPlacement = @"D2SPlacement";

@implementation GUIController


+ (void)initialize 
{
	// register defaults
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:D2SReplace];
	[defaultValues setObject:[NSNumber numberWithBool:NO] forKey:D2SOrganize];
	[defaultValues setObject:@"Bookmarks" forKey:D2SPlacement];
	[defaultValues setObject:@"" forKey:D2SLogin];
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:D2SPasswordAsk];
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
}


- (void)awakeFromNib 
{
	delicious = nil;
	// get password field contents from keychain
	NSString *pass;
	NSString *login = [[NSUserDefaults standardUserDefaults] stringForKey:D2SLogin];
	if ([login length] > 0) {
		if (pass = [self getPasswordForUser:login]) {
			[passField setStringValue:pass];
		}
	}
}


- (IBAction)cancelGetBookmarks:(id)sender 
{
	[delicious cancelGetBookmarks];
}


- (IBAction)getBookmarks:(id)sender 
{
	// without this, values don't always get synched to user defaults
	[mainWindow endEditingFor:loginField];
	[mainWindow endEditingFor:passField];
	
	NS_DURING
		
		NSString *login = [[NSUserDefaults standardUserDefaults] stringForKey:D2SLogin];
		NSString *password = [passField stringValue];
		BOOL replace = [[NSUserDefaults standardUserDefaults] boolForKey:D2SReplace];		
		BOOL organize =  [[NSUserDefaults standardUserDefaults] boolForKey:D2SOrganize];
		NSString *placement = [[NSUserDefaults standardUserDefaults] stringForKey:D2SPlacement];

		// check if we have a login
		if ([login length] < 1)
			[[NSException exceptionWithName:@"NoLogin" 
									 reason:@"You did not enter a login." 
								   userInfo:nil] raise];
		
		
		if ([password length] < 1)
			[[NSException exceptionWithName:@"NoPass" 
									 reason:@"You did not enter a password." 
								   userInfo:nil] raise];
		
		// handle keychain password
		NSString *keychainPassword = [self getPasswordForUser:login];
		BOOL askPassSave = [[NSUserDefaults standardUserDefaults] boolForKey:D2SPasswordAsk];
		
		if ((keychainPassword == nil) && askPassSave) {
			// no keychain password stored yet
			int returnCode = [genericSheetController runModalSheet:saveInKeychainSheet];
			if (returnCode == NSAlertFirstButtonReturn) {
				// store password in keychain
				if (![self addPassword:password forUser:login]) {
					[[NSException exceptionWithName:@"KeychainAddError" 
											 reason:@"An error occurred while adding the password to the keychain." 
										   userInfo:nil] raise];					
				}
			} else if (returnCode == NSAlertThirdButtonReturn) {
				// don't store and never ask again
				[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"D2SPasswordAsk"];
			}
		} else if ((keychainPassword) && ![keychainPassword isEqualToString:password]) {
			// stored password and current password differ
			int returnCode = [genericSheetController runModalSheet:updateKeychainSheet];
			if (returnCode == NSAlertFirstButtonReturn) {
				// update keychain password
				if (![self updatePassword:password forUser:login]) {
					[[NSException exceptionWithName:@"KeychainUpdateError" 
											 reason:@"An error occurred while updating the keychain." 
										   userInfo:nil] raise];
				}
			} else if (returnCode == NSAlertThirdButtonReturn) {
				// use keychain password instead of the one the user entered
				password = keychainPassword;
			}
		}
		
		// switch to second tab, start progress indicator
		[tabView selectLastTabViewItem:self];
		[tabView display];
		[cancelButton setHidden:NO];
		[progressIndicator setHidden:NO];
		[progressIndicator startAnimation:self];
		
		// create delicious bookmarks controller
		delicious = [[DeliciousToSafari alloc] init];
		
		// register for changes in status while bookmarks are being retrieved
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(changeStatus:)
													 name:D2SProgress 
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(syncHasFinished:)
													 name:D2SEnd 
												   object:nil];		
		
		// let DeliciousToSafari object handle the rest
		[delicious getBookmarksUsingUsername:login
									password:password
									organize:organize
									 replace:replace
								   placement:placement
									delegate:self];
		
		NS_HANDLER

			// catch exceptions
			
			if ([[localException name] isEqualToString:@"NoLogin"]) {
				[infoSheetController runModalWithMessage:[localException reason]
												 details:@"Your del.icio.us username is required to retrieve your bookmarks."
												  button:@"Ok"];
			}
			
			if ([[localException name] isEqualToString:@"NoPass"]) {
				[infoSheetController runModalWithMessage:[localException reason]
												 details:@"Your del.icio.us password is required to retrieve your bookmarks."
												  button:@"Ok"];
			}
			
			if ([[localException name] isEqualToString:@"KeychainUpdateError"]) {
				[infoSheetController runModalWithMessage:[localException reason]
												 details:@"Your new password was not saved in the keychain."
												  button:@"Ok"];
			}
			
			if ([[localException name] isEqualToString:@"KeychainAddError"]) {
				[infoSheetController runModalWithMessage:[localException reason]
												 details:@"Your new password was not saved in the keychain."
												  button:@"Ok"];
			}
				
		NS_ENDHANDLER
}	


- (BOOL)updatePassword:(NSString *)password forUser:(NSString *)account 
{
	NSString *serviceName = @"delicious2safari";
	SecKeychainItemRef keychainItem;
	OSStatus status = SecKeychainFindGenericPassword(
													 NULL, // use default keychain
													 [serviceName length],
													 [serviceName UTF8String],
													 [account length],
													 [account UTF8String],
													 0,
													 NULL,
													 &keychainItem
													 );
	if (status == 0) {
		status = SecKeychainItemModifyAttributesAndData (
														 keychainItem, 
														 NULL,         
														 [password length],
														 [password UTF8String]       
														 );
	}
	return(status == 0);
}


- (NSString *)getPasswordForUser:(NSString *)account 
{
	NSString *serviceName = @"delicious2safari";
	UInt32 plength;
	void *p;
	OSStatus status = SecKeychainFindGenericPassword(NULL, // use default keychain
													 [serviceName length],
													 [serviceName UTF8String],
													 [account length],
													 [account UTF8String],
													 &plength,
													 &p,
													 NULL);
	if (status == 0) {
		return [NSString stringWithCString:p length:plength];
	} else {
		return nil;
	}
}


- (BOOL)addPassword:(NSString *)pass forUser:(NSString *)account 
{
	NSString *serviceName = @"delicious2safari";
	OSStatus status = SecKeychainAddGenericPassword(NULL, // use default keychain
													[serviceName length],
													[serviceName UTF8String],
													[account length],
													[account UTF8String],
													[pass length],
													[pass UTF8String],
													NULL);
	return(status == 0);
}


- (BOOL)shouldReplaceBookmarksFile 
{
	[progressIndicator stopAnimation:self];
	int returnCode = [genericSheetController runModalSheet:replaceSheet];
	[progressIndicator startAnimation:self];	
	if (returnCode == NSAlertFirstButtonReturn) return YES;
	else return NO;
}


- (void)changeStatus:(NSNotification *)notification 
{
	[statusField setStringValue:[notification object]];
	[tabView display];
}


- (void)syncHasFinished:(NSNotification *)notification 
{
	int status = [[notification object] intValue];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[delicious release];
	delicious = nil;
	
	// stop progress indicator
	[cancelButton setHidden:YES];
	[progressIndicator stopAnimation:self];
	[progressIndicator setHidden:YES];
	[tabView display];
	
	// update display according to return value from [delicious getBookmarks...]
	// see DeliciousToSafari.h for definition of return codes
	switch (status) {
		case D2SSuccess :{
			[quitButton setHidden:NO];
			[quitButton highlight:YES];
			[statusField setStringValue:@"Finished updating your bookmarks."];
		}
			break;
		// non-fatal errors
		case D2SAccessDenied : {
			[tabView selectFirstTabViewItem:self];
			[tabView display];
			[infoSheetController runModalWithMessage:@"Incorrect login or password."
											 details:@"The del.icio.us server did not accept the login/password combination."
											  button:@"Ok"];
		}
			break;
		case D2SNetworkError : {
			[tabView selectFirstTabViewItem:self];
			[tabView display];
			[infoSheetController runModalWithMessage:@"Could not retrieve bookmarks from server."
											 details:@"You may be experiencing network or server problems. Please check your network connection or try again later."
											  button:@"Ok"];
		}
			break;
		case D2SCancelConfirmation : {
			[delicious release];
			[tabView selectFirstTabViewItem:self];
			[tabView display];
			[infoSheetController runModalWithMessage:@"Download cancelled."
											 details:@"No changes have been made to your bookmarks."
											  button:@"Ok"];
		}
			break;
		// fatal errors
		case D2SEmptyResponse : {
			[infoSheetController runModalWithMessage:@"Empty response from server."
											 details:@"This is likely a temporary server failure, or caused by changes to the del.icio.us system. Please check the delicious2safari website for current issues, and try again later."
											  button:@"Quit"];
			[[NSApplication sharedApplication] terminate:self];
		};
			break;
		case D2SParseError : {
			[infoSheetController runModalWithMessage:@"Could not parse response from del.icio.us."
											 details:@"This is likely a temporary server failure, or caused by changes to the del.icio.us system. Please check the delicious2safari website for current issues, and try again later."
											  button:@"Quit"];
			[[NSApplication sharedApplication] terminate:self];
		};
			break;
		case D2SBookmarksFileNotFound : {
			NSString *path = [NSHomeDirectory() stringByAppendingString:@"/Library/Safari/Bookmarks.plist"];
			[infoSheetController runModalWithMessage:@"Could not find your Safari bookmarks file."
											 details:[@"The application expects your bookmarks to be in " stringByAppendingString:path]
											  button:@"Quit"];
			[[NSApplication sharedApplication] terminate:self];
		};
			break;
		case D2SBookmarksFileFormatError : {
			[infoSheetController runModalWithMessage:@"Safari bookmarks are not in the expected format."
											 details:@"No changes were made to your Safari bookmarks. When reporting this problem, please include a copy of your Safari bookmarks file."
											  button:@"Quit"];
			[[NSApplication sharedApplication] terminate:self];
		};
			break;
		case D2SBackupError : {
			[infoSheetController runModalWithMessage:@"Could not backup your Safari bookmarks."
											 details:@"No changes were made to your Safari bookmarks."
											  button:@"Quit"];
			[[NSApplication sharedApplication] terminate:self];
		};
			break;
		default : {
			[infoSheetController runModalWithMessage:@"Internal error."
											 details:@"No changes were made to your Safari bookmarks. Please file a bug report."
											  button:@"Quit"];
			[[NSApplication sharedApplication] terminate:self];
		};
			break;
	}	
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

@end
