//
//  GUIController.h
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

#import <Cocoa/Cocoa.h>

// keys for user defaults
extern NSString *D2SLogin;         // del.icio.us login name
extern NSString *D2SPasswordAsk;   // don't ask any more to save password in keychain
extern NSString *D2SReplace;       // don't ask before replacing entries named "del.icio.us" in bookmarks
extern NSString *D2SOrganize;      // organize del.icio.us bookmarks in folders according to tags
extern NSString *D2SPlacement;     // where to place downloaded bookmarks (possible values: Bookmarks, Bookmarks Menu, Bookmarks Bar)

@class DeliciousToSafari, GenericSheetController, InfoSheetController;

/*!
	@class GUIController
	Controller for the main window.
 */
@interface GUIController : NSObject
{
	IBOutlet NSWindow *mainWindow;
	IBOutlet NSTabView *tabView;
	IBOutlet NSTextField *statusField;
	IBOutlet NSButton *quitButton;
	IBOutlet NSButton *cancelButton;
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSTextField *loginField;
	IBOutlet NSTextField *passField;
	IBOutlet NSPanel *replaceSheet;
	IBOutlet NSPanel *updateKeychainSheet;
	IBOutlet NSPanel *saveInKeychainSheet;
	IBOutlet GenericSheetController *genericSheetController;
	IBOutlet InfoSheetController *infoSheetController;
	
	DeliciousToSafari *delicious;  // object actually handling the bookmarks
}


// Actions

- (IBAction)getBookmarks:(id)sender;
- (IBAction)cancelGetBookmarks:(id)sender;

// Keychain password handling

- (NSString *)getPasswordForUser:(NSString *)account;
- (BOOL)addPassword:(NSString *)pass forUser:(NSString *)account;
- (BOOL)updatePassword:(NSString *)password forUser:(NSString *)account;

// SafariHelper delegate methods

- (BOOL)shouldReplaceBookmarksFile;

// DeliciousToSafari notification methods
- (void)changeStatus:(NSNotification *)notification;
- (void)syncHasFinished:(NSNotification *)notification;


// NSApplication delegate methods

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;

@end
