/* UIPauseButton.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
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

#import "UIPauseButton.h"
#import "LinphoneManager.h"

#include "linphonecore.h"
#include "private.h"

@implementation UIPauseButton

- (void)initUIPauseButton {
    self->type = UIPauseButtonType_CurrentCall;
}

- (id)init{
    self = [super init];
    if (self) {
		[self initUIPauseButton];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
		[self initUIPauseButton];
	}
    return self;
}	

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self initUIPauseButton];
    }
    return self;
}

- (void)setType:(UIPauseButtonType) atype call:(LinphoneCall*)acall {
    self->type = atype;
    self->call = acall;
}

- (void)onOn {
    switch (type) {
        case UIPauseButtonType_Call:
        {
            if (call != nil) {
                linphone_core_pause_call([LinphoneManager getLc], call);
            }
            break;
        }
        case UIPauseButtonType_Conference:
        {
            linphone_core_leave_conference([LinphoneManager getLc]);
            
            // Fake event
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LinphoneCallUpdate" object:self];
            break;
        }
        case UIPauseButtonType_CurrentCall:
        {
            LinphoneCall* currentCall = [UIPauseButton getCall];
            if (currentCall != nil) {
                linphone_core_pause_call([LinphoneManager getLc], currentCall);
            }
            break;
        }
    }
}

- (void)onOff {
    switch (type) {
        case UIPauseButtonType_Call:
        {
            if (call != nil) {
                linphone_core_resume_call([LinphoneManager getLc], call);
            }
            break;
        }
        case UIPauseButtonType_Conference:
        {
            linphone_core_enter_conference([LinphoneManager getLc]);
            // Fake event
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LinphoneCallUpdate" object:self];
            break;
        }
        case UIPauseButtonType_CurrentCall:
        {
            LinphoneCall* currentCall = [UIPauseButton getCall];
            if (currentCall != nil) {
                linphone_core_resume_call([LinphoneManager getLc], currentCall);
            }
            break;
        }
    }
}

+ (bool)isInConference: (LinphoneCall*) call {
    if (!call)
        return false;
    return linphone_call_get_current_params(call)->in_conference;
}

+ (int)notInConferenceCallCount: (LinphoneCore*) lc {
    int count = 0;
    const MSList* calls = linphone_core_get_calls(lc);
    
    while (calls != 0) {
        if (![UIPauseButton isInConference: (LinphoneCall*)calls->data]) {
            count++;
        }
        calls = calls->next;
    }
    return count;
}

- (bool)onUpdate {
    bool ret = false;
    // TODO: disable pause on not running call
    if([LinphoneManager isLcReady]) {
        LinphoneCore *lc = [LinphoneManager getLc];
        switch (type) {
            case UIPauseButtonType_Call:
            {
                if (call != nil) {
                    LinphoneCallState state = linphone_call_get_state(call);
                    if(state == LinphoneCallPaused || state == LinphoneCallPausing) {
                        ret = true;
                    }
                    [LinphoneManager set:self enabled:TRUE withName:"PAUSE button" andReason:""];
                } else {
                    [LinphoneManager set:self enabled:FALSE withName:"PAUSE button" andReason:""];
                }
                break;
            }
            case UIPauseButtonType_Conference:
            {
                if(linphone_core_get_conference_size(lc) > 0) {
                    if (!linphone_core_is_in_conference(lc)) {
                            ret = true;
                    }
                    [LinphoneManager set:self enabled:TRUE withName:"PAUSE button" andReason:""];
                } else {
                    [LinphoneManager set:self enabled:FALSE withName:"PAUSE button" andReason:""];
                }
                break;
            }
            case UIPauseButtonType_CurrentCall:
            {
                LinphoneCall* currentCall = [UIPauseButton getCall];
                if (currentCall != nil) {
                    LinphoneCallState state = linphone_call_get_state(currentCall);
                    if(state == LinphoneCallPaused || state == LinphoneCallPausing) {
                        ret = true;
                    }
                    [LinphoneManager set:self enabled:TRUE withName:"PAUSE button" andReason:""];
                } else {
                    [LinphoneManager set:self enabled:FALSE withName:"PAUSE button" andReason:""];
                }
                break;
            }
        }
    } 
    return ret;
}

+ (LinphoneCall*)getCall {
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneCall* currentCall = linphone_core_get_current_call(lc);
	if (currentCall == nil && linphone_core_get_calls_nb(lc) == 1) {
        currentCall = (LinphoneCall*) linphone_core_get_calls(lc)->data;
    }
    return currentCall;
}

- (void)dealloc {
    [super dealloc];
}

@end
