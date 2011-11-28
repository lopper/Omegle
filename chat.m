//
//  chat.m
//  chat
//
//  Created by Philip Bernstein on 9/7/11.
//  Copyright 2011 oZeta Designs. All rights reserved.
//

#import "chat.h"
#define BASE_SAVE "OMEGLE_CHAT_"

@implementation chat
@synthesize chatName, initiated, delegate, baseChatURL, frequency, users;
- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
-(id)newChatWithDelegate:(id)del
{
    self = [super init];
    if (self) {
        self.frequency = 4;
        self.initiated = NO;
        self.chatName = NULL;
        
        if (del)
            self.delegate = del;
        
        
        // we **ALWAYS** fetch the BASE URL, because omegle has a tendency to change this. DO NOT REMOVE.
        
        // funny -- I removed it like 10 minutes after writing that comment ^.^
    }
    
    return self;
}
-(void)beginChat 
{
    [self getBaseURL];
}
-(void)getBaseURL {

    NSURL *url = [NSURL URLWithString:@"http://omegle.com"];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    baseURLConnection = [[NSURLConnection alloc] initWithRequest:req delegate:self];

}
-(void)startChat {
    // yay now we actually start the chat.
    NSString *complete = [NSString stringWithFormat:@"%@start", self.baseChatURL];
   // NSLog(@"connection to: %@, starting chat.", complete);
    NSURL *url = [NSURL URLWithString:complete];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    startConnection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    
}
-(void)disconnectChat {
    [eventsTimer invalidate];
    NSString *events =@"/disconnect";
    events = [NSString stringWithFormat:@"%@disconnect", self.baseChatURL];
    NSLog(@"URL: %@", events);
    NSMutableURLRequest *eventsRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:events]];
    [eventsRequest setHTTPMethod:@"POST"];
    NSString *postString = [@"id=" stringByAppendingString:self.chatName];
    NSLog(@"Post Data: %@", postString);
    [eventsRequest setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    disconnectConnection = [[NSURLConnection alloc] initWithRequest:eventsRequest delegate:self];

}
-(void)startTyping {
    if (self.chatName != NULL || self.chatName != nil)
    {
    NSString *events =@"/typing";
    events = [NSString stringWithFormat:@"%@typing", self.baseChatURL];
    NSLog(@"URL: %@", events);
    NSMutableURLRequest *eventsRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:events]];
    [eventsRequest setHTTPMethod:@"POST"];
    NSString *postString = [@"id=" stringByAppendingString:self.chatName];
    NSLog(@"Post Data: %@", postString);
    [eventsRequest setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    startTypingConnection = [[NSURLConnection alloc] initWithRequest:eventsRequest delegate:self];
    }

}
-(void)stopTyping {
    if (self.chatName != NULL || self.chatName != nil)
    {
    NSString *events =@"/stoppedtyping";
    events = [NSString stringWithFormat:@"%@typing", self.baseChatURL];
    NSLog(@"URL: %@", events);
    NSMutableURLRequest *eventsRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:events]];
    [eventsRequest setHTTPMethod:@"POST"];
    NSString *postString = [@"id=" stringByAppendingString:self.chatName];
    NSLog(@"Post Data: %@", postString);
    [eventsRequest setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    stoppedTypingConnection = [[NSURLConnection alloc] initWithRequest:eventsRequest delegate:self];
    }
}
-(bool)saveChatInDefaults:(NSString *)object {
    
    return true;
}
-(NSArray *)fetchChatFromDefaults:(NSString *)object {
    
    
    return nil;
}
-(NSArray *)listAllSavedChats {
    
    return nil;

}
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSString *mat = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // will never be more than two chunks (other than BASEURL, but we dont need to append that data, we only care about the second one)
    if (connection == baseURLConnection)
    {
        NSString *dat = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self baseURLDidReceiveData:dat];
        [dat release];
        
        
    }
    else if (connection == startConnection)
    {
        NSString *dat = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        [self chatBeganWithID:dat];
        [dat release];
    }
    else if (connection == eventsURL)
    {
        NSString *dat = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self eventsDidReceiveData:dat];
         [dat release];
    }
    else if (connection == sendConnection)
    {
        // WHO CARES
        NSLog(@"Message Success: ?= %@", mat);
    }
    else if (connection == startTypingConnection)
    {
        NSLog(@"Started Typing: ?= %@", mat);
    }
    else if (connection == stoppedTypingConnection)
    {
        NSLog(@"Stopped Typing: ?= %@", mat);
    }
    else if (connection == disconnectConnection)
    {
        if ([self.delegate respondsToSelector:@selector(chatDidDisconnect:)])
        {
            [self.delegate chatDidDisconnect:self];
        }
        else {
            [self chatDidDisconnect:self];
        }
    }
    else if ([mat isEqualToString:@"win"] || [mat isEqualToString:@"fail"])
    {
        
    }
    else {
        // probably the events one.
        [self eventsDidReceiveData:mat];
    }
             [mat release];
}
-(void)baseURLDidReceiveData:(NSString *)data
{
    if ([data rangeOfString:@"<frame src="].location != NSNotFound)
    {
        // yaya we got the base URL
        // this could probably be condensed to one line, but I'm a lazy ass hole.
        int location = [data rangeOfString:@"<frame src="].location + 12;
        NSString *base = [data substringFromIndex:location];
        base = [base substringToIndex:[base rangeOfString:@"omegle.com"].location + 11];
        //NSLog(@"BASE URL SAVED: %@", base);
        self.baseChatURL = base;
        [self startChat];
        
    }
    else {
        // sadface, we didnt get it. maybe next chunk? :)
        
        // thought to ponder: Omegle changes 'unofficial' API, WTF happens? LOL. 
        // should probably have a fail safe of some kind
        // defaults to bajor.omegle.com if no base URL is found
        // this is fine for now though
        // if you feel like helping......... :)
    }
}
-(void)chatBeganWithID:(NSString *)chatID
{
   NSLog(@"CHAT BEGAN WITH ID: %@", chatID);
    chatID = [chatID stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    self.chatName = chatID;
    self.initiated = true;
   [self checkEvents];
    eventsTimer = [NSTimer scheduledTimerWithTimeInterval: self.frequency target:self selector:@selector(checkEvents) userInfo:nil repeats: YES];
    if ([self.delegate respondsToSelector:@selector(chatDidStart:withID:)])
    {
        [self.delegate chatDidStart:self withID:chatID];
    }
    else {
        [self chatDidStart:self withID:chatID];

    }

    
}
-(void)checkEvents
{
    NSString *events = [NSString stringWithFormat:@"%@events", self.baseChatURL];
    //NSLog(@"URL: %@", events);
    NSMutableURLRequest *eventsRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:events]];
    [eventsRequest setHTTPMethod:@"POST"];
    NSString *postString = [@"id=" stringByAppendingString:self.chatName];
    //NSLog(@"Post Data: %@", postString);
    [eventsRequest setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    eventsURL = [[NSURLConnection alloc] initWithRequest:eventsRequest delegate:self];

}
-(void)eventsDidReceiveData:(NSString *)dat
{
    if (![dat isEqualToString:@"null"])
    {
    //NSLog(@"RESPONSE: %@", dat);
    NSArray *response = [dat JSONValue];
    int total = response.count;
    int start = 1;
    int array = 0;
    while (total >= start)
    {
        if ([[[response objectAtIndex: array] objectAtIndex:0] isEqualToString:@"strangerDisconnected"]) {
            // user disconnected
            NSLog(@"STRANGER_DISCONNECTED");
            if ([self.delegate respondsToSelector:@selector(chatDidDisconnect:)])
            {
                [self.delegate chatDidDisconnect:self];
            }
            else {
                [self chatDidDisconnect:self];
            }
            [eventsTimer invalidate];
        }
        if ([[[response objectAtIndex: array] objectAtIndex:0] isEqualToString:@"gotMessage"]) {
            NSString *chatMessage = [[response objectAtIndex:array] objectAtIndex:1];
            NSLog(@"GOT_MESSAGE: %@", chatMessage);
            if ([self.delegate respondsToSelector:@selector(chatDidReceiveMessage:inChat:)])
            {
                [self.delegate chatDidReceiveMessage:chatMessage inChat:self];
            }
            else {
                [self chatDidReceiveMessage:chatMessage inChat:self];
            }
        }
        if ([[[response objectAtIndex: array] objectAtIndex:0] isEqualToString:@"connected"]) {
            NSLog(@"USER_CONNECTED");
            if ([self.delegate respondsToSelector:@selector(userConnectedInChat:)])
            {
                [self.delegate userConnectedInChat:self];
            }
            else {
                [self userConnectedInChat:self];
            }
        }
        if ([[[response objectAtIndex: array] objectAtIndex:0] isEqualToString:@"waiting"]) {
            NSLog(@"WAITING");
        }
        if ([[[response objectAtIndex: array] objectAtIndex:0] isEqualToString:@"count"]) {
            
            self.users = [[[response objectAtIndex:array] objectAtIndex:1] intValue];
            NSLog(@"USER_COUNT: %d", self.users);
        }
        if ([[[response objectAtIndex: array] objectAtIndex:0] isEqualToString:@"typing"]) {
            NSLog(@"USER_TYPING");
            if ([self.delegate respondsToSelector:@selector(chatStartedTyping:)])
            {
                [self.delegate chatStartedTyping:self];
            }
            else {
                [self chatStartedTyping:self];
            }
        }
        if ([[[response objectAtIndex: array] objectAtIndex:0] isEqualToString:@"stoppedTyping"]) {
            NSLog(@"STOPPED_TYPING");
            if ([self.delegate respondsToSelector:@selector(chatStoppedTyping:)])
            {
                [self.delegate chatStoppedTyping:self];
            }
            else {
                [self chatStoppedTyping:self];
            }
        }
        
        start++;
        array++;
    }
    }
}
-(void)sendMessage:(NSString *)message
{
    if (self.initiated && message != NULL)
    {
    message = [message stringByAddingPercentEscapesUsingEncoding:
             NSASCIIStringEncoding];
    
    NSString *events =@"/send";
    events = [NSString stringWithFormat:@"%@send", self.baseChatURL];
    NSMutableURLRequest *eventsRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:events]];
    [eventsRequest setHTTPMethod:@"POST"];
    NSString *postString = [@"id=" stringByAppendingString:self.chatName];
    postString = [postString stringByAppendingString:@"&msg="];
    postString = [postString stringByAppendingString:message];
    NSLog(@"Post Data: %@", postString);
    [eventsRequest setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    sendConnection = [[NSURLConnection alloc] initWithRequest:eventsRequest delegate:self];
    }

}
-(void)getResponseFromRobot:(NSString *)message {
    
    // LETS DO THIS.
}
-(void)userConnectedInChat:(id)chat
{
    NSLog(@"user connected");
}
/*

 Only here as fallback methods, please incorporate this into your own class.
 
*/
-(void)chatDidReceiveMessage:(NSString *)message inChat:(id)chat {
    
}
-(void)chatDidStart:(id)chat withID:(NSString *)chatID {
    
}
-(void)chatDidDisconnect:(id)chat {
    
}
-(void)chatStartedTyping:(id)chat {
    
}
-(void)chatStoppedTyping:(id)chat {
    
}
-(void)exit
{
    [eventsTimer invalidate];
    [self disconnectChat];
}
@end
