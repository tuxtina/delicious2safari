//
//  SafariHelper.h
//  delicious2safari
//
//  Created by Christina Zeeh on 2004-09-28.
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
#import "DeliciousToSafari.h"


/*!
	@class SafariHelper
	Converts simple dictionary of bookmarks to the format required for use in 
	Safari's bookmark file, and writes the converted bookmarks to Safari's 
	bookmarks.
 */
@interface SafariHelper : NSObject {
	id delegate;
	BOOL organize;
	BOOL replace;
	NSString *placement;
	NSString *safariBookmarksPath;
	NSString *backupPath;
}

- (id)initWithDelegate:(id)aDelegate
			   organize:(BOOL)anOrganize 
			   replace:(BOOL)aReplace
			 placement:(NSString *)aPlacement;

- (void)dealloc;

- (D2SStatus)writeBookmarks:(NSMutableDictionary *)downloadedBookmarks;

// private methods
- (NSMutableDictionary *)newFolderWithName:(NSString *)name;
- (NSMutableDictionary *)newBookmarkWithTitle:(NSString *)title href:(NSString *)href;
- (NSMutableDictionary *)buildSafariBookmarksEntryFrom:(NSMutableDictionary *)bookmarks;

@end
