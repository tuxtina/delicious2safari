//
//  GenericSheetController.m
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

#import "GenericSheetController.h"

@implementation GenericSheetController

- (int)runModalSheet:(NSPanel *)aPanel 
{
    [NSApp beginSheet:aPanel 
	   modalForWindow:mainWindow
		modalDelegate:self 
	   didEndSelector:NULL 
		  contextInfo:NULL];
	int returnCode = [NSApp runModalForWindow:aPanel];
    [NSApp endSheet:aPanel];
    [aPanel orderOut:NULL];
	return(returnCode);
}


- (IBAction)endSheetFirstButton:(id)sender 
{
	[NSApp stopModalWithCode:NSAlertFirstButtonReturn];
}


- (IBAction)endSheetSecondButton:(id)sender 
{
	[NSApp stopModalWithCode:NSAlertSecondButtonReturn];
}


- (IBAction)endSheetThirdButton:(id)sender 
{
	[NSApp stopModalWithCode:NSAlertThirdButtonReturn];
}

@end
