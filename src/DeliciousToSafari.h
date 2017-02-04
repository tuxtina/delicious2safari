//
//  DeliciousToSafari.h
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

#import <Cocoa/Cocoa.h>

@class Downloader, DownloadManager, SafariHelper;

// status codes
typedef enum {
	D2SSuccess,
	D2SInternalError,
	D2SCancelConfirmation,
	D2SAccessDenied,
	D2SNetworkError,
	D2SEmptyResponse,
	D2SParseError,
	D2SBookmarksFileNotFound,
	D2SBookmarksFileFormatError,
	D2SBackupError
} D2SStatus;

// notifications DeliciousToSafari receives
extern NSString *D2SBookmarksDone;
extern NSString *D2SDone;
extern NSString *D2SError;

// notifications DeliciousToSafari posts
extern NSString *D2SCancel;
extern NSString *D2SProgress;
extern NSString *D2SEnd;

/*!
	@class DeliciousToSafari
	Controls the downloading and importing process.
*/
@interface DeliciousToSafari : NSObject 
{
	Downloader *downloader;
	SafariHelper *safariHelper;
	BOOL cancelled;
}

- (id)init;
- (void)dealloc;

- (void)getBookmarksUsingUsername:(NSString *)aUsername
						 password:(NSString *)aPassword
						 organize:(BOOL)organize
						  replace:(BOOL)replace
						placement:(NSString *)placement
						 delegate:(id)delegate;


// private methods
- (void)cancelGetBookmarks;
- (void)confirmCancellation;
- (void)writeBookmarks:(NSMutableDictionary *)bookmarks;

// methods for notifications from Downloader
- (void)downloadedBookmarks:(NSNotification *)notification;
- (void)abortedDownloadWithError:(NSNotification *)notification;

@end
