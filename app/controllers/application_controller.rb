class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  # returns an array of userIds of the opponents of a bet
  def get_bet_opponents(bet_id)
    opps = []
    Bet.find(bet_id).invites.each do |i|
      opps.push i.invitee if i.status == "accepted"
    end
    return opps
  end

  def push_notify_user(uid = "", msg = "hello")
    usr = User.where(fb_id: uid).first
    if usr
      begin
        APNS.send_notification(usr.device, alert: msg, badge: 1, sound: 'default')
      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
      end
    end
  end

  def push_notify_users(userIdList = [], msg = "hello")
    notifs = []
    userIdList.each do |usrId|
      usr = User.where(fb_id: usrId).first
      if usr
        notifs.push(
          APNS::Notification.new(
            usr.device, 
            alert: msg, 
            badge: 1, 
            sound: 'default'
          )
        )
      end
    end
    APNS.send_notifications(notifs)
  end
end
