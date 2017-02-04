//
//  Downloader.h
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
#import "DeliciousToSafari.h"

/*!
	@class Downloader
	Downloads tags/bookmarks from del.icio.us and returns them as simple 
	dictionaries through notifications.
 */
@interface Downloader : NSObject 
{
	NSString *user;
	NSString *pass;
	NSMutableData *rawDownload;
	NSMutableDictionary *processedDownload;
	NSURLConnection *connection;
	NSTimer *timer;
}

- (id)initWithUsername:(NSString *)aUsername
			  password:(NSString *)aPassword;
- (void)dealloc;

- (void)getBookmarks;

// private methods
- (void)cancelDownload:(id)notificationOrTimer; 
- (void)processDownload;
- (void)cleanupAndNotifyDelegateWithStatus:(D2SStatus)status;

// NSURLConnection delegate methods
- (void)connection:(NSURLConnection *)connection 
  didFailWithError:(NSError *)error;

- (void)connection:(NSURLConnection *)connection 
	didReceiveData:(NSData *)data;

- (void)connection:(NSURLConnection *)connection 
	didReceiveResponse:(NSURLResponse *)response;

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

- (void)connection:(NSURLConnection *)connection
	didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

- (NSURLRequest *)connection:(NSURLConnection *)connection
			 willSendRequest:(NSURLRequest *)request
			redirectResponse:(NSURLResponse *)redirectResponse;


@end
