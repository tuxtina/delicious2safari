//
//  GenericSheetController.h
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
	@class GenericSheetController
	Runs a generic sheet with up to three buttons modal for the application.
 */
@interface GenericSheetController : NSObject
{
	IBOutlet NSWindow *mainWindow; // main window the sheet should be attached to
}

- (int)runModalSheet:(NSPanel *)aPanel;

- (IBAction)endSheetFirstButton:(id)sender;
- (IBAction)endSheetSecondButton:(id)sender;
- (IBAction)endSheetThirdButton:(id)sender;

@end
