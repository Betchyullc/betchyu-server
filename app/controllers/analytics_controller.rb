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
    big_loc = 0
    big_loc = locs.select do |loc|
      if big_loc < loc[:amount]
        big_loc = loc[:amount]
        true
      end
    end.last
    sec_loc = 0
    sec_loc = locs.select do |loc|
      if sec_loc < loc[:amount] && big_loc[:amount] > loc[:amount]
        sec_loc = loc[:amount]
        true
      end
    end.last
    last_loc = User.count
    last_loc = locs.select do |loc|
      if last_loc > loc[:amount]
        last_loc = loc[:amount]
        true
      end
    end.last

    render json: {
      :"Total Unique Users" => User.count,
      :"Percent Male" => User.where(is_male: true).count.to_f / User.count * 100,
#      :"Average Age" => tot_age.to_f / User.count,
      :"Locations" => {
        :"Total Unique Locations" => locs.count,
        :"Most Common" => big_loc,
        :"Second Most Common" => sec_loc,
        :"Least Common" => last_loc
      }
    }
  end

  def daily
    day = params[:day] ? params[:day].to_date : nil
    if day == nil
      start = Bet.first.created_at.to_date
      days = (Date.today - start).to_i

      # totals, which become averages we report
      new_goals = 0
      accepted_invites = 0
      won_bets = 0
      lost_bets = 0
      dollars_added = 0

      # go through each day, updating the totals
      days.times do |iter|
        d = start + iter
        invites_today = Invite.where('status = ? AND updated_at >= ? AND updated_at < ?', "accepted", d.to_time.beginning_of_day, (d+1).to_time.beginning_of_day)
        invites_today.each do |i|
          dollars_added += i.bet.stakeAmount
        end
        new_goals += Bet.where('created_at >= ? AND created_at < ?', d.to_time.beginning_of_day, (d+1).to_time.beginning_of_day).count
        accepted_invites += invites_today.count
        won_bets += Bet.where('status = ? AND updated_at >= ? AND updated_at < ?', "won", d.to_time.beginning_of_day, (d+1).to_time.beginning_of_day).count
        lost_bets += Bet.where('status = ? AND updated_at >= ? AND updated_at < ?', "lost", d.to_time.beginning_of_day, (d+1).to_time.beginning_of_day).count
      end
      # make an average by dividing
      new_goals = new_goals.to_f / days
      accepted_invites = accepted_invites.to_f / days
      won_bets = won_bets.to_f / days
      lost_bets = lost_bets.to_f / days
      dollars_added = dollars_added.to_f / days

      # print out the report
      render json: {
        :"Days Covered by this Report" => days,
        :"Average Daily Goals Created" => new_goals,
        :"Average Daily Invites Accepted" => accepted_invites,
        :"Average Daily Bets Won by Owner" => won_bets,
        :"Average Daily Bets Lost by Owner" => lost_bets,
        :"Average Daily Dollars Added to Account" => dollars_added
      }
    else
      invites_today = Invite.where('status = ? AND updated_at >= ? AND updated_at < ?', "accepted", day.to_time.beginning_of_day, (day+1).to_time.beginning_of_day)
      dollars = 0
      invites_today.each do |i|
        dollars += i.bet.stakeAmount
      end
      render json: {
        :"Data for Day #{day}" => {
          :"Goals Created" => Bet.where('created_at >= ? AND created_at < ?', day.to_time.beginning_of_day, (day+1).to_time.beginning_of_day).count,
          :"Invites Accepted" => invites_today.count,
          :"Bets Won by Owner" => Bet.where('status = ? AND updated_at >= ? AND updated_at < ?', "won", day.to_time.beginning_of_day, (day+1).to_time.beginning_of_day).count,
          :"Bets Lost by Owner" => Bet.where('status = ? AND updated_at >= ? AND updated_at < ?', "lost", day.to_time.beginning_of_day, (day+1).to_time.beginning_of_day).count,
          :"Dollars Added to Account" => dollars
        }
      }
    end
  end

  def need_to_buy
    day = params[:day] ? params[:day].to_date : nil

    render json: "no day given, dumbass" if day == nil
    return if day == nil
    
    trans_arr = Transaction.where('submitted = ? AND updated_at >= ? AND updated_at < ?', true, day.to_time.beginning_of_day, (day+1).to_time.beginning_of_day).to_a
    things_to_buy = {
      amazon: [],
      target: [],
      itunes: []
    }
    trans_arr.each do |t|
      usr = User.where(fb_id: t.to).first
      push_obj = {
        amount: t.bet.stakeAmount,
        destination: usr.email ? usr.email : usr.id
      }
      things_to_buy[:amazon].push(push_obj) if t.bet.stakeType == "Amazon Gift Card"
      things_to_buy[:target].push(push_obj) if t.bet.stakeType == "Target Gift Card"
      things_to_buy[:itunes].push(push_obj) if t.bet.stakeType == "iTunes Gift Card"
    end
    render json: things_to_buy
  end

  private
    def global_password
      unless params[:pw] && params[:pw] == Server::Application.config.pw
        render json: "You don't have access to this data, fool."
      end
    end
end
