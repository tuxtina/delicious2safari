//
//  DeliciousToSafari.m
//  delicious2safari
//
//  Created by Christina Zeeh on 2004-09-27.
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

#import "DeliciousToSafari.h"
#import "Downloader.h"
#import "SafariHelper.h"

// notifications DeliciousToSafari receives
NSString *D2SDone = @"D2SDone";
NSString *D2SError = @"D2SError";

// notifications DeliciousToSafari posts
NSString *D2SCancel = @"D2SCancel";
NSString *D2SProgress = @"D2SProgress";
NSString *D2SEnd = @"D2SEnd";


@implementation DeliciousToSafari


- (id)init 
{
	self = [super init];
	downloader = nil;
	safariHelper = nil;
	cancelled = YES;
	return self;
}


- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[downloader release];
	[safariHelper release];
	[super dealloc];
}


- (void)getBookmarksUsingUsername:(NSString *)aUsername
						 password:(NSString *)aPassword
						 organize:(BOOL)organize
						  replace:(BOOL)replace
						placement:(NSString *)placement
						 delegate:(id)delegate 
{
	
	cancelled = NO;

	[[NSNotificationCenter defaultCenter] postNotificationName:D2SProgress 
														object:@"Starting download ..."];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(downloadedBookmarks:)
												 name:D2SDone
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(abortedDownloadWithError:)
												 name:D2SError
											   object:nil];
	
	downloader = [[Downloader alloc] initWithUsername:aUsername
											 password:aPassword];
	
	safariHelper = [[SafariHelper alloc] initWithDelegate:delegate
												 organize:organize
												  replace:replace
												placement:placement];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:D2SProgress 
														object:@"Retrieving bookmarks ..."];
	[downloader getBookmarks];
}


- (void)cancelGetBookmarks 
{
	[[NSNotificationCenter defaultCenter] postNotificationName:D2SCancel
														object:nil];
	cancelled = YES; 
}


- (void)confirmCancellation 
{
	[[NSNotificationCenter defaultCenter] postNotificationName:D2SEnd
														object:[NSNumber numberWithInt:D2SCancelConfirmation]];
}


- (void)writeBookmarks:(NSMutableDictionary *)bookmarks 
{
	// make sure we don't continue & give feedback if user cancelled
	if (cancelled) {
		[self confirmCancellation];
		return;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:D2SProgress 
														object:@"Writing bookmarks ..."];	
	D2SStatus status = [safariHelper writeBookmarks:bookmarks];
	[[NSNotificationCenter defaultCenter] postNotificationName:D2SEnd 
														object:[NSNumber numberWithInt:status]];
}


- (void)downloadedBookmarks:(NSNotification *)notification 
{
	// make sure we don't continue & give feedback if user cancelled
	if (cancelled) {
		[self confirmCancellation];
		return;
	}
	
	NSMutableDictionary *bookmarks = [notification object];

	#ifdef DEBUG
		NSLog(@"Received download successful message with %i bookmarks.",[bookmarks count]);
	#endif

	[self writeBookmarks:bookmarks];
}


- (void)abortedDownloadWithError:(NSNotification *)notification 
{
	#ifdef DEBUG
		NSLog(@"Received download error message: %@", [notification object]);
	#endif
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:D2SEnd 
														object:[notification object]];
}


@end
