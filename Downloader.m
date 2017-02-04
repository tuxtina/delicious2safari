//
//  Downloader.m
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

#import "Downloader.h"

int timeout = 60;
NSString *baseURL = @"https://api.del.icio.us/v1/posts/all";
NSString *userAgent = @"delicious2safari/1.2.1";

@implementation Downloader

- (id)initWithUsername:(NSString *)aUsername
			  password:(NSString *)aPassword
{
	self = [super init];
	user = [aUsername retain];
	pass = [aPassword retain];
	rawDownload = nil;
	processedDownload = nil;
	connection = nil;
	timer = nil;
	return self;
}


- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[user release];
	[pass release];
	[super dealloc];
}

- (void)getBookmarks
{
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(cancelDownload:) 
												 name:D2SCancel 
											   object:nil];	
	
	connection = nil;
	rawDownload = nil;
	processedDownload = nil;

	NSURL *url = [NSURL URLWithString:baseURL];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
													cachePolicy:NSURLRequestReloadIgnoringCacheData
												timeoutInterval:timeout];
	
	[request setValue:userAgent forHTTPHeaderField:@"User-Agent"];

	timer = [NSTimer scheduledTimerWithTimeInterval:timeout
											 target:self
										   selector:@selector(cancelDownload:)
										   userInfo:nil
											repeats:NO];
	
	connection = [[NSURLConnection alloc] initWithRequest:request
												 delegate:self];

	if (connection) {
		rawDownload = [[NSMutableData data] retain];
	} else {
		[self cleanupAndNotifyDelegateWithStatus:D2SInternalError];
	}		
}


- (void)cleanupAndNotifyDelegateWithStatus:(D2SStatus)status 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[connection release];
	
	NSNotification *notification;
	
	if (status == D2SSuccess) {
		notification = [NSNotification notificationWithName:D2SDone
													 object:processedDownload];
		[[NSNotificationQueue defaultQueue] enqueueNotification:notification
												   postingStyle:NSPostWhenIdle];
	} else {
		notification = [NSNotification notificationWithName:D2SError
													 object:[NSNumber numberWithInt:status]];
		[[NSNotificationQueue defaultQueue] enqueueNotification:notification
												   postingStyle:NSPostWhenIdle];
	}
}


- (void)cancelDownload:(id)notificationOrTimer 
{
	#ifdef DEBUG
		NSLog(@"Cancelling download.");
	#endif

	if (notificationOrTimer == timer) {
		[connection cancel];
		[self cleanupAndNotifyDelegateWithStatus:D2SNetworkError];
	} else {
		[timer invalidate];
		[connection cancel];
		[self cleanupAndNotifyDelegateWithStatus:D2SCancelConfirmation];
	}
}


- (void)processDownload 
{
	processedDownload = [NSMutableDictionary dictionary];
	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:rawDownload];
	if (!parser) {
		[self cleanupAndNotifyDelegateWithStatus:D2SParseError];
		return;
	}
	
	[parser setDelegate:self]; 
	
	if (![parser parse]) {
		[parser release];
		[self cleanupAndNotifyDelegateWithStatus:D2SParseError];
		return;
	}

	[parser release];
	[self cleanupAndNotifyDelegateWithStatus:D2SSuccess];
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
										namespaceURI:(NSString *)namespaceURI 
									   qualifiedName:(NSString *)qName 
										  attributes:(NSDictionary *)attributeDict 
{
	if ( [elementName isEqualToString:@"post"] ) {
			NSString *href = [attributeDict objectForKey:@"href"];
			[processedDownload setObject:attributeDict forKey:href];
		return;
	} 
}


// NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error 
{
	#ifdef DEBUG
		NSLog(@"Connection failed with error: %@", error);
	#endif

	[timer invalidate];
	
	NSString *domain = [error domain];
	int code = [error code];
	if ([domain isEqualToString:NSURLErrorDomain] && (code == NSURLErrorUserCancelledAuthentication)) {
		[self cleanupAndNotifyDelegateWithStatus:D2SAccessDenied];
	} else {
		[self cleanupAndNotifyDelegateWithStatus:D2SNetworkError];
	}
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data 
{
	#ifdef DEBUG
		NSLog(@"Received data.");
	#endif
	
	[timer setFireDate:[[NSDate date] addTimeInterval:timeout]];
	
	[rawDownload appendData:data];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response 
{
	#ifdef DEBUG
		NSLog(@"Received response.");
	#endif

	[timer setFireDate:[[NSDate date] addTimeInterval:timeout]];
	
	[rawDownload setLength:0];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
	#ifdef DEBUG
		NSLog(@"Finished loading. Loaded %i bytes.", [rawDownload length]);
	#endif
	[timer invalidate];
	
	if ([rawDownload length] == 0) {
		[self cleanupAndNotifyDelegateWithStatus:D2SEmptyResponse];
	} else {
		[self processDownload];
	}
}


-(void)connection:(NSURLConnection *)connection
	didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge 
{
	#ifdef DEBUG
		NSLog(@"Received authentication challenge.");
	#endif
	
	[timer setFireDate:[[NSDate date] addTimeInterval:timeout]];
	
    if ([challenge previousFailureCount] == 0) {
        NSURLCredential *newCredential;
        newCredential=[NSURLCredential credentialWithUser:user
                                                 password:pass
                                              persistence:NSURLCredentialPersistenceForSession];

        [[challenge sender] useCredential:newCredential
               forAuthenticationChallenge:challenge];
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
		// error will be handled by connection:didFailWithError:
    }	
}


- (NSURLRequest *)connection:(NSURLConnection *)connection
			 willSendRequest:(NSURLRequest *)request
			redirectResponse:(NSURLResponse *)redirectResponse 
{
	#ifdef DEBUG	
		NSLog(@"Redirect.");
	#endif
	
	[timer setFireDate:[[NSDate date] addTimeInterval:timeout]];
	
	NSURLRequest *newRequest=request;
	
	if (redirectResponse) {
		newRequest=nil;
	}

	return newRequest;
}


@end
