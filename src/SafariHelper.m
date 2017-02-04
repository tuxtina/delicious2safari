//
//  SafariHelper.m
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

#import "SafariHelper.h"
#import "XMLStringUtilities.h"

@implementation SafariHelper

- (id)initWithDelegate:(id)aDelegate
			  organize:(BOOL)anOrganize 
			   replace:(BOOL)aReplace
			 placement:(NSString *)aPlacement 
{
	self = [super init];
	delegate = [aDelegate retain];
	organize = anOrganize;
	replace = aReplace;
	placement = [aPlacement retain];
	safariBookmarksPath = [[NSHomeDirectory() stringByAppendingString:@"/Library/Safari/Bookmarks.plist"] retain];
	backupPath = [[NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/delicious2safari/Bookmarks.backup"] retain];
	return self;
}


- (void)dealloc 
{
	[placement release];
	[delegate release];
	[safariBookmarksPath release];
	[backupPath release];
	[super dealloc];
}


- (D2SStatus)writeBookmarks:(NSMutableDictionary *)downloadedBookmarks 
{
	[[NSNotificationCenter defaultCenter] postNotificationName:D2SProgress 
														object:@"Processing bookmarks ..."];

	if (!downloadedBookmarks) {
		return D2SParseError;
	}
	
	NSMutableDictionary *deliciousBookmarks = [self buildSafariBookmarksEntryFrom:downloadedBookmarks];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:D2SProgress 
														object:@"Writing bookmarks ..."];
	
	// check for presence of a Safari bookmarks file
	if (![[NSFileManager defaultManager] fileExistsAtPath:safariBookmarksPath]) {
		return(D2SBookmarksFileNotFound);
	}
	
	// load Safari bookmarks into dictionary
	NSMutableDictionary *bookmarks = 
		[NSMutableDictionary dictionaryWithContentsOfFile:safariBookmarksPath];
	if (!bookmarks)	{
		return(D2SBookmarksFileFormatError);
	}
	
	// children is the top level array of the Safari bookmarks, containing
	// dicts for the Bookmarks Menu, Bookmarks Bar etc. as well as user-definied
	// top-level folders
	NSMutableArray *children = [bookmarks objectForKey:@"Children"];
	if (!children) {
		return(D2SBookmarksFileFormatError);
	}

	// find target for inserting bookmarks according to user's desired placement
	NSMutableArray *target = nil;
	if ([placement isEqualToString:@"Bookmarks"]) {
		target = children;	
	} else if ([placement isEqualToString:@"Bookmarks Menu"]) {
		NSEnumerator *childEnum = [children objectEnumerator];
		NSMutableDictionary *entry;
		while (entry = [childEnum nextObject]) {
			if ([[entry objectForKey:@"Title"] isEqualToString:@"BookmarksMenu"]) {
				if (!(target = [entry objectForKey:@"Children"])) {
					// empty Bookmarks Menu
					target = [[NSMutableArray alloc] init];
					[entry setObject:target forKey:@"Children"];
					[target release];					
				}
			}
		}
	} else if ([placement isEqualToString:@"Bookmarks Bar"]) {
		NSEnumerator *childEnum = [children objectEnumerator];
		NSMutableDictionary *entry;
		while (entry = [childEnum nextObject]) {
			if ([[entry objectForKey:@"Title"] isEqualToString:@"BookmarksBar"]) {
				if (!(target = [entry objectForKey:@"Children"])) {
					// empty Bookmarks Bar
					target = [[NSMutableArray alloc] init];
					[entry setObject:target forKey:@"Children"];
					[target release];
				}				
			}
		}
	}
	
	// look for other folders named del.icio.us
	// note: each folder has a unique ID, so adding more folders with the
	// same name does not cause any problems other than possible user confusion
	NSEnumerator *targetEnum = [target objectEnumerator];
	NSMutableDictionary *entry;
	BOOL foundExistingEntry = NO;
	BOOL insertedNewBookmarks = NO;
	while ((!foundExistingEntry) && (entry = [targetEnum nextObject])){
		if (([[entry objectForKey:@"Title"] isEqualToString:@"del.icio.us"]) && 
			([[entry objectForKey:@"WebBookmarkType"] isEqualToString:@"WebBookmarkTypeList"])) {
			
			foundExistingEntry = YES;
			
			if (!replace) {
				// ask delegate
				if ([delegate shouldReplaceBookmarksFile]) {
					replace = YES;
				}
			}
			
			if (replace) {
				insertedNewBookmarks = YES;
				// replace existing children array with new children array
				[entry setObject:[deliciousBookmarks objectForKey:@"Children"] forKey:@"Children"]; 
			} 
		}
	}
	
	// insert downloaded bookmarks in Safari bookmarks, if we did not replace anything
	if (!insertedNewBookmarks) {
		[target addObject:deliciousBookmarks];
	}
	
	// create a backup in ~/Library/Application Support/delicious2safari
	NSString *backupDir = [backupPath stringByDeletingLastPathComponent];
	if (![[NSFileManager defaultManager] fileExistsAtPath:backupDir]) {
		if (![[NSFileManager defaultManager] createDirectoryAtPath:backupDir attributes:nil]) {
			return(D2SBackupError);
		}
	}
	if ([[NSFileManager defaultManager] fileExistsAtPath:backupPath]) {
		if (![[NSFileManager defaultManager] removeFileAtPath:backupPath handler:nil]) {
			return(D2SBackupError);
		}
	}
	if (![[NSFileManager defaultManager] copyPath:safariBookmarksPath toPath:backupPath handler:nil]) {
		return(D2SBackupError);
	}
	
	// write bookmarks file
	[bookmarks writeToFile:safariBookmarksPath atomically:YES];
	
	return(D2SSuccess);
}


- (NSMutableDictionary *)newFolderWithName:(NSString *)name
{
	// create empty bookmarks folder
	NSMutableDictionary *newFolder = [NSMutableDictionary dictionaryWithCapacity:4];
	// children array will contain entries (bookmarks/subfolders)
	NSMutableArray *newChildren = [NSMutableArray array];
	// generate a new newUUID for the del.icio.us bookmarks folder
	NSString *newUUID = (NSString *) CFUUIDCreateString(kCFAllocatorDefault, 
														CFUUIDCreate(kCFAllocatorDefault));
	
	// add information for del.icio.us folder in bookmarks file
	[newFolder setObject:name forKey:@"Title"];
	[newFolder setObject:@"WebBookmarkTypeList" forKey:@"WebBookmarkType"];
	[newFolder setObject:newUUID forKey:@"WebBookmarkUUID"];
	[newFolder setObject:newChildren forKey:@"Children"];
	
	[newUUID release];
	
	return newFolder;
}


- (NSMutableDictionary *)newBookmarkWithTitle:(NSString *)title href:(NSString *)href 
{
	// create new bookmark entry
	NSMutableDictionary *newBookmark = [NSMutableDictionary dictionaryWithCapacity:4];

	// bookmarks contain an "URIDictionary"
	NSMutableDictionary *newURIDict =  [NSMutableDictionary dictionaryWithCapacity:2];
	[newURIDict setObject:href forKey:@""];
	[newURIDict setObject:title forKey:@"title"];
				
	// set properties of the new bookmark entry
	NSString *newUUID = (NSString *) CFUUIDCreateString(kCFAllocatorDefault, 
																	CFUUIDCreate(kCFAllocatorDefault));
	[newBookmark setObject:newURIDict forKey:@"URIDictionary"];
	[newBookmark setObject:href forKey:@"URLString"];
	[newBookmark setObject:@"WebBookmarkTypeLeaf" forKey:@"WebBookmarkType"];
	[newBookmark setObject:newUUID forKey:@"WebBookmarkUUID"];
	
	[newUUID release];
	
	return newBookmark;
}


- (NSMutableDictionary *)buildSafariBookmarksEntryFrom:(NSMutableDictionary *)bookmarks 
{
	// sort bookmarks
	NSSortDescriptor *descriptionDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"description" 
																		   ascending:YES
																			selector:@selector(caseInsensitiveCompare:)] autorelease];
	
	NSArray *sortDescriptors = [NSArray arrayWithObject:descriptionDescriptor];
	NSArray *sortedBookmarks = [[bookmarks allValues] sortedArrayUsingDescriptors:sortDescriptors];
	
	NSMutableDictionary *deliciousFolder = [self newFolderWithName:@"del.icio.us"];
	NSMutableArray *deliciousEntries = [deliciousFolder objectForKey:@"Children"];
	
	NSMutableDictionary *tags = [NSMutableDictionary dictionary];
	
	NSEnumerator *bookmarksEnumerator = [sortedBookmarks objectEnumerator];
	NSDictionary *bookmarkData;
	while (bookmarkData = [bookmarksEnumerator nextObject]) {
		
		NSString *href = [[bookmarkData objectForKey:@"href"] stringByUnescapingEntities];
		NSString *description = [[bookmarkData objectForKey:@"description"] stringByUnescapingEntities];
		
		#ifdef DEBUG
			NSLog(@"Processing %@ :: %@.",href,description);
		#endif
		
		// build bookmark entry
		NSMutableDictionary *newBookmark = [self newBookmarkWithTitle:description
																 href:href];
		
		if (organize) {
			NSString *tagsCombined = [[bookmarkData objectForKey:@"tag"] stringByUnescapingEntities];
			NSArray *tagsSplitted = [tagsCombined componentsSeparatedByString:@" "];
			NSEnumerator *tagsEnumerator = [tagsSplitted objectEnumerator];
			NSString *tag;
			while (tag = [tagsEnumerator nextObject]) {
				NSMutableDictionary *tagFolder = [tags objectForKey:tag];
				if (!tagFolder) {
					tagFolder = [self newFolderWithName:tag];
					[tags setObject:tagFolder forKey:tag];
					[deliciousEntries addObject:tagFolder];
				}
			NSMutableArray *tagFolderChildren = [tagFolder objectForKey:@"Children"];
			[tagFolderChildren addObject:newBookmark];
			}
			
			// sort tag folders alphabetically
			NSSortDescriptor *titleDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"Title" 
																			 ascending:YES
																			  selector:@selector(caseInsensitiveCompare:)] autorelease];
			
			sortDescriptors = [NSArray arrayWithObject:titleDescriptor];
			NSArray *sortedEntries = [deliciousEntries sortedArrayUsingDescriptors:sortDescriptors];
			
			[deliciousFolder setObject:sortedEntries forKey:@"Children"];

		} else {
			[deliciousEntries addObject:newBookmark];
		}
	}
	
	return deliciousFolder;
}


@end
