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
end
