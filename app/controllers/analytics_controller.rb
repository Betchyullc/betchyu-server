class AnalyticsController < ApplicationController
  before_action :global_password, only: [:standard, :demographics]
  
  def standard
    tot_bets = Bet.all.count
    avg_bet_dur = 0
    Bet.all.each {|b| avg_bet_dur += b.duration}
    avg_bet_dur = avg_bet_dur / tot_bets
    total_won = Bet.where(status: "won").count
    bounced_users = []
    active_users = []
    User.all.each do |u|
      invs = Invite.where(invitee: u.fb_id, status: "accepted").to_a
      active_invs = []
      invs.each {|i| active_invs.push(i) if i.bet.status == "accepted"}

      bounced_users.push(u) if invs.count == 0 && Bet.where(owner: u.fb_id).count == 0
      active_users.push(u) if active_invs.count != 0 || Bet.where('owner = ? AND (status = ? OR status = ?)', u.fb_id, "pending", "accepted").count != 0
    end

    report = {
      :"Total bets created" => tot_bets,
      :"Total by type" => {
        Smoking: Bet.where(verb: 'Stop').count,
        Weight:  Bet.where(verb: 'Lose').count,
        Running: Bet.where(verb: 'Run').count,
        Workout: Bet.where(verb: 'Workout').count
      },
      :"Average bet duration" => avg_bet_dur,
      :"Total invites sent" => Invite.count,
      :"Average invites per bet" => Invite.count.to_f / tot_bets,
      :"Total validated invites accepted" => Invite.where(status: "accepted").count,
      :"Percent invites accepted" => Invite.where(status: "accepted").count.to_f / Invite.count * 100,
      :"Total bets won by owner" => total_won,
      :"Percent bets won by owner" => total_won.to_f / tot_bets * 100,
      :"percent won by type" => {
        Smoking: Bet.where(status: "won", verb: 'Stop').count.to_f / total_won * 100,
        Weight: Bet.where(status: "won", verb: 'Lose').count.to_f / total_won * 100,
        Running: Bet.where(status: "won", verb: 'Run').count.to_f / total_won * 100,
        Workout: Bet.where(status: "won", verb: 'Workout').count.to_f / total_won * 100,
      },
      :"Total unique users" => User.count,
      :"Percent users only opened once" => bounced_users.count.to_f / User.count,
      :"Total active users" => active_users.count,
      :"Total active bets" => Bet.where('status = ? OR status = ?', "pending", "accepted").count
    }
    render json: report
  end

  def demographics
#    tot_age = 0
#    User.all.each {|u| tot_age += u.age.to_i if u.age}
    locs = []
    User.all.each do |u|
      matched = false
      locs.each do |loc|
        if loc[:name] == u.location
          matched = true 
          loc[:amount] += 1
        end
      end
      unless matched
        locs.push({name: u.location, amount: 1}) if u.location
      end
    end

    render json: {
      :"Total Unique Users" => User.count,
      :"Percent Male" => User.where(is_male: true).count.to_f / User.count * 100,
#      :"Average Age" => tot_age.to_f / User.count,
      :"Locations" => {
        :"Most Common" => "bah",
        :"Second Most Common" => "blah"
      }
    }
  end

  private
    def global_password
      unless params[:pw] && params[:pw] == Server::Application.config.pw
        render json: "You don't have access to this data, fool."
      end
    end
end
