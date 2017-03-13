//
//  WCXMPPTool.m
//  weChat
//
//  Created by XSUNT45 on 17/3/10.
//  Copyright © 2017年 XSUNT45. All rights reserved.
//

#import "WCXMPPTool.h"
@import XMPPFramework;

/*
 * 在AppDelegate实现登录
 
 1. 初始化XMPPStream
 2. 连接到服务器[传一个JID]
 3. 连接到服务成功后，再发送密码授权
 4. 授权成功后，发送"在线" 消息
 */

@interface WCXMPPTool ()<XMPPStreamDelegate> {
    XMPPResultsBlock _resultBlock;
    
    XMPPvCardCoreDataStorage *_vCardStorage;//电子名片的数据存储
    XMPPvCardAvatarModule *_avatar;//头像模块
    
    XMPPReconnect *_reconnect; //自动连接模块
    
    XMPPMessageArchiving *_msgArchiving;//聊天模块
    
}

// 1. 初始化XMPPStream
-(void)setupXMPPStream;


// 2.连接到服务器
-(void)connectToHost;

// 3.连接到服务成功后，再发送密码授权
-(void)sendPwdToHost;


// 4.授权成功后，发送"在线" 消息
-(void)sendOnlineToHost;

@end

@implementation WCXMPPTool

WSSingletonM(WCXMPPTool)


#pragma mark  -私有方法
#pragma mark 初始化XMPPStream
-(void)setupXMPPStream{
    
    _xmppStream = [[XMPPStream alloc] init];
    
    
    //添加电子名片模块
    _vCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
    _vCard = [[XMPPvCardTempModule alloc] initWithvCardStorage:_vCardStorage];
    //激活
    [_vCard activate:_xmppStream];
    
    //添加头像模块
    _avatar = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:_vCard];
    [_avatar activate:_xmppStream];
    
    //添加自动连接模块
    _reconnect = [[XMPPReconnect alloc] init];
    [_reconnect activate:_xmppStream];
    
    // 添加花名册模块【获取好友列表】
    _rosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    _roster = [[XMPPRoster alloc] initWithRosterStorage:_rosterStorage];
    [_roster activate:_xmppStream];
    
    // 添加聊天模块
    _msgStorage = [[XMPPMessageArchivingCoreDataStorage alloc] init];
    _msgArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:_msgStorage];
    [_msgArchiving activate:_xmppStream];
    
    // 设置代理
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

#pragma mark 连接到服务器
-(void)connectToHost{
    NSLog(@"开始连接到服务器");
    if (!_xmppStream) {
        [self setupXMPPStream];
    }
    
    
    // 设置登录用户JID
    //resource 标识用户登录的客户端 iphone android
    
    // 从沙盒获取用户名
    NSString *user = nil;
    if (self.isRegisterOperation) { //注册
        user = [WCUserInfo sharedWCUserInfo].registerUser;
    } else { //登录
        user = [WCUserInfo sharedWCUserInfo].user;
    }
    
    XMPPJID *myJID = [XMPPJID jidWithUser:user domain:@"teacher.local" resource:@"iphone" ];
    _xmppStream.myJID = myJID;
    
    // 设置服务器域名
    _xmppStream.hostName = @"teacher.local";//不仅可以是域名，还可是IP地址
    
    // 设置端口 如果服务器端口是5222，可以省略
    _xmppStream.hostPort = 5222;
    
    // 连接
    NSError *err = nil;
    if(![_xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&err]){
        NSLog(@"%@",err);
    }
    
}


#pragma mark 连接到服务成功后，再发送密码授权
-(void)sendPwdToHost{
    NSLog(@"再发送密码授权");
    NSError *err = nil;
    
    // 从沙盒里获取密码
    NSString *pwd = [WCUserInfo sharedWCUserInfo].pwd;
    
    [_xmppStream authenticateWithPassword:pwd error:&err];
    if (err) {
        NSLog(@"%@",err);
    }
}

#pragma mark  授权成功后，发送"在线" 消息
-(void)sendOnlineToHost{
    
    NSLog(@"发送 在线 消息");
    XMPPPresence *presence = [XMPPPresence presence];
    NSLog(@"%@",presence);
    
    [_xmppStream sendElement:presence];
    
    
}
#pragma mark -XMPPStream的代理
#pragma mark 与主机连接成功
-(void)xmppStreamDidConnect:(XMPPStream *)sender{
    NSLog(@"与主机连接成功");
    
    if (self.isRegisterOperation) {//注册操作，发送注册的密码
        NSString *pwd = [WCUserInfo sharedWCUserInfo].registerPwd;
        [_xmppStream registerWithPassword:pwd error:nil];
    }else{//登录操作
        // 主机连接成功后，发送密码进行授权
        [self sendPwdToHost];
    }
}
#pragma mark  与主机断开连接
-(void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error{
    // 如果有错误，代表连接失败
    NSLog(@"与主机断开连接 %@",error);
    if(error && _resultBlock){
        _resultBlock(XMPPResultTypeNetErr);
    }
    
}


#pragma mark 授权成功
-(void)xmppStreamDidAuthenticate:(XMPPStream *)sender{
    NSLog(@"授权成功");
    
    [self sendOnlineToHost];
    
    // 回调控制器登录成功
    if(_resultBlock){
        _resultBlock(XMPPResultTypeLoginSuccess);
    }
    
    
}


#pragma mark 授权失败
-(void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error{
    
    NSLog(@"授权失败 %@",error);
    // 判断block有无值，再回调给登录控制器
    if (_resultBlock) {
        _resultBlock(XMPPResultTypeLoginFailure);
    }
}


#pragma mark -公共方法
-(void)logout{
    // 1." 发送 "离线" 消息"
    XMPPPresence *offline = [XMPPPresence presenceWithType:@"unavailable"];
    [_xmppStream sendElement:offline];
    
    // 2. 与服务器断开连接
    [_xmppStream disconnect];
}

-(void)xmppUserLogin:(XMPPResultsBlock)result{
    _resultBlock = result;
    
    // 如果以前连接过服务，要断开
    [_xmppStream disconnect];
    // 连接主机 成功后发送密码
    [self connectToHost];
}

#pragma mark - 注销
-(void)xmppUserlogout {
    // 1." 发送 "离线" 消息"
    XMPPPresence *offline = [XMPPPresence presenceWithType:@"unavailable"];
    [_xmppStream sendElement:offline];
    
    // 2. 与服务器断开连接
    [_xmppStream disconnect];
    
    // 3. 回到登录界面
    [UIStoryboard showInitialVCWithName:@"login"];
    
    //4.更新用户的登录状态
    [WCUserInfo sharedWCUserInfo].loginStatus = NO;
    [[WCUserInfo sharedWCUserInfo] saveUserInfoToSanbox];
}

#pragma mark - 注册
-(void)xmppUserRegister:(XMPPResultsBlock)resultBlock{
    // 先把block存起来
    _resultBlock = resultBlock;
    
    // 如果以前连接过服务，要断开
    [_xmppStream disconnect];
    
    // 连接主机 成功后发送注册密码
    [self connectToHost];
}

#pragma mark 注册成功
-(void)xmppStreamDidRegister:(XMPPStream *)sender{
    NSLog(@"注册成功");
    if(_resultBlock){
        _resultBlock(XMPPResultTypeRegisterSuccess);
    }
    
}

#pragma mark 注册失败
-(void)xmppStream:(XMPPStream *)sender didNotRegister:(DDXMLElement *)error{
    
    NSLog(@"注册失败 %@",error);
    if(_resultBlock){
        _resultBlock(XMPPResultTypeRegisterFailure);
    }
    
}

- (void)dealloc {
    [self teardownStream];
}

#pragma mark - 释放xmppStream相关资源
- (void)teardownStream {
    //移除代理
    [_xmppStream removeDelegate:self];
    
    //停止模块
    [_reconnect deactivate];
    [_vCard deactivate];
    [_avatar deactivate];
    [_roster deactivate];
    [_msgArchiving deactivate];
    
    //断开链接
    [_xmppStream disconnect];
    
    //清空资源
    _reconnect = nil;
    _vCard = nil;
    _vCardStorage = nil;
    _avatar = nil;
    _roster = nil;
    _rosterStorage = nil;
    _msgArchiving = nil;
    _msgStorage = nil;
    _xmppStream = nil;
    
}



@end
