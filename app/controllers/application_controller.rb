require 'bcrypt'
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
    if usr && usr.device
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
      if usr && usr.device
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

  def verify_user
    unless params[:uid].present? && params[:pw].present?
      render json: "not authenticated"
      return
    end
    real_pw = params[:pw] + "abc123betchyu"
    usr = User.where(fb_id: params[:uid]).first
    if usr
      render json: "bad authentication" unless usr.password == real_pw 
    else
      render json: "not authenticated"
    end
    # the user is legit if we get here
  end

  def match_uid_and_id
    render json: { msg: "you can't see this" } unless params[:uid] && params[:id] && params[:uid] == params[:id]
  end
end
