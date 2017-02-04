//
//  InfoSheetController.h
//  delicious2safari
//
//  Created by Christina Zeeh on 2004-09-23.
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

/*!
	@class InfoSheetController
	Runs an info sheet with a single button modal for the application.
 */
@interface InfoSheetController : NSObject
{
	IBOutlet NSWindow *mainWindow; // window the sheet will be attached to
    IBOutlet NSPanel *panelWindow; // sheet window
    IBOutlet NSTextField *details; // message text (bold)
    IBOutlet NSTextField *message; // informative text (smaller)
	IBOutlet NSButton *okButton;   // Ok Button (can be used as quit button)
}

- (void)runModalWithMessage:(NSString *)aMsg 
					details:(NSString *)aDetails 
					 button:(NSString *)aCaption;

- (IBAction)dismissPanel:(id)sender;

@end
