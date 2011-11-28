//
//  chat.h
//  chat
//
//  Created by Philip Bernstein on 9/7/11.
//  Copyright 2011 oZeta Designs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSON.h"

@class chat;
@protocol OmegleDelegate
@optional
-(void)chatDidReceiveMessage:(NSString *)message inChat:(id)chat;
-(void)chatDidStart:(id)chat withID:(NSString *)chatID;
-(void)chatDidDisconnect:(id)chat;
-(void)chatStartedTyping:(id)chat;
-(void)chatStoppedTyping:(id)chat;
-(void)userConnectedInChat:(id)chat;
@end
@interface chat : NSObject <OmegleDelegate>
{
    NSURLConnection *baseURLConnection;
    NSURLConnection *startConnection;
    NSURLConnection *eventsURL;
    NSTimer *eventsTimer;
    NSURLConnection *sendConnection;
    NSURLConnection *disconnectConnection;
    NSURLConnection *robotConnection;
    
    // Typing, BLECH.
    NSURLConnection *startTypingConnection;
    NSURLConnection *stoppedTypingConnection;
}
-(id)newChatWithDelegate:(id)del;
-(void)getBaseURL;
-(void)startChat;
-(void)exit;
-(void)disconnectChat;
-(void)startTyping;
-(void)stopTyping;
-(bool)saveChatInDefaults:(NSString *)object;
-(NSArray *)fetchChatFromDefaults:(NSString *)object;
-(NSArray *)listAllSavedChats;
-(void)baseURLDidReceiveData:(NSString *)data;
-(void)beginChat;
-(void)chatBeganWithID:(NSString *)chatID;
-(void)checkEvents;
-(void)eventsDidReceiveData:(NSString *)dat;
-(void)sendMessage:(NSString *)message;
-(void)getResponseFromRobot:(NSString *)message;
NSString * myData();

@property (nonatomic, retain) NSString *chatName;
@property (nonatomic) bool initiated;
@property (nonatomic, retain) id delegate;
@property (nonatomic, retain) NSString *baseChatURL;
@property (nonatomic) int frequency;
@property (nonatomic) int users;
@end
