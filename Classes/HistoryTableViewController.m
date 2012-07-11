/* HistoryTableViewController.m
 *
 * Copyright (C) 2009  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or   
 *  (at your option) any later version.                                 
 *                                                                      
 *  This program is distributed in the hope that it will be useful,     
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of      
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       
 *  GNU General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License   
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */     

#import "HistoryTableViewController.h"
#import "UIHistoryCell.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"

@implementation HistoryTableViewController

@synthesize missedFilter;

#pragma mark - Lifecycle Functions

- (void)initHistoryTableViewController {
    callLogs = [[NSMutableArray alloc] init];
    missedFilter = false;
}

- (id)init {
    self = [super init];
    if (self) {
		[self initHistoryTableViewController];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
		[self initHistoryTableViewController];
	}
    return self;
}	

- (void)dealloc {
    [callLogs release];
    [super dealloc];
}


#pragma mark - Property Functions

- (void)setMissedFilter:(BOOL)amissedFilter {
    self->missedFilter = amissedFilter;
    [[self tableView] reloadData];
}


#pragma mark - UITableViewDataSource Functions

- (void)loadData {
    [callLogs removeAllObjects];
	const MSList * logs = linphone_core_get_call_logs([LinphoneManager getLc]);
    while(logs != NULL) {
        LinphoneCallLog*  log = (LinphoneCallLog *) logs->data;
        if(missedFilter) {
            if (log->status == LinphoneCallMissed) {
                [callLogs addObject:[NSValue valueWithPointer: log]];
            }
        } else {
            [callLogs addObject:[NSValue valueWithPointer: log]];
        }
        logs = ms_list_next(logs);
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    [self loadData];
	return [callLogs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kCellId = @"UIHistoryCell";
    UIHistoryCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId];
    if (cell == nil) {
        cell = [[[UIHistoryCell alloc] initWithIdentifier:kCellId] autorelease];
    }
    
    LinphoneCallLog *log = [[callLogs objectAtIndex:[indexPath row]] pointerValue];
    [cell setCallLog:log];
	
    return cell;
}


#pragma mark - UITableViewDelegate Functions

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
    LinphoneCallLog *log = [[callLogs objectAtIndex:[indexPath row]] pointerValue];
	LinphoneAddress* partyToCall; 
	if (log->dir == LinphoneCallIncoming) {
		partyToCall=log->from;
	} else {
		partyToCall=log->to;
	}
	const char* username = linphone_address_get_username(partyToCall)!=0?linphone_address_get_username(partyToCall):"";
	const char* displayName = linphone_address_get_display_name(partyToCall)!=0?linphone_address_get_display_name(partyToCall):"";
	const char* domain = linphone_address_get_domain(partyToCall);
	
	LinphoneProxyConfig* proxyCfg;
	linphone_core_get_default_proxy([LinphoneManager getLc],&proxyCfg);
	
	NSString* phoneNumber;
	
	if (proxyCfg && (strcmp(domain, linphone_proxy_config_get_domain(proxyCfg)) == 0)) {
		phoneNumber = [[NSString alloc] initWithCString:username encoding:[NSString defaultCStringEncoding]];
	} else {
		phoneNumber = [[NSString alloc] initWithCString:linphone_address_as_string_uri_only(partyToCall) encoding:[NSString defaultCStringEncoding]];
	}
    
    NSString* dispName = [[NSString alloc] initWithCString:displayName encoding:[NSString defaultCStringEncoding]];
    
    // Go to dialer view
    NSDictionary *dict = [[[NSDictionary alloc] initWithObjectsAndKeys:
                          [[[NSArray alloc] initWithObjects: phoneNumber, dispName, nil] autorelease]
                          , @"call:displayName:",
                          nil] autorelease];
    [[PhoneMainView instance] changeView:PhoneView_Dialer dict:dict];

	[phoneNumber release];
    [dispName release];
}

@end

