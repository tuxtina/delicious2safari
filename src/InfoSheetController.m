//
//  InfoSheetController
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

#import "InfoSheetController.h"

@implementation InfoSheetController

- (IBAction)dismissPanel:(id)sender
{
	[NSApp stopModalWithCode:NSOKButton];

}


- (void)runModalWithMessage:(NSString *)aMsg 
					details:(NSString *)aDetails
					 button:(NSString *)aCaption
{
	[message setStringValue:aMsg];
	[details setStringValue:aDetails];
	[okButton setTitle:aCaption];
	[NSApp beginSheet:panelWindow 
	   modalForWindow:mainWindow
		modalDelegate:self 
	   didEndSelector:NULL 
		  contextInfo:NULL];
	[NSApp runModalForWindow:panelWindow];
    [NSApp endSheet:panelWindow];
    [panelWindow orderOut:NULL];
}

@end
