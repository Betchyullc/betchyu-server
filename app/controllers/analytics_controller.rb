class AnalyticsController < ApplicationController
  before_action :global_password, only: [:standard_report]
  
  def standard_report
    tot_bets = Bet.all.count
    avg_bet_dur = 0
    Bet.all.each {|b| avg_bet_dur += b.duration}
    avg_bet_dur = avg_bet_dur / tot_bets
    total_won = Bet.where(status: "won").count

    report = {
      total_bets_created: tot_bets,
      by_type: {
        smoking: Bet.where(verb: 'Stop').count,
        weight:  Bet.where(verb: 'Lose').count,
        running: Bet.where(verb: 'Run').count,
        workout: Bet.where(verb: 'Workout').count
      },
      average_bet_duration: avg_bet_dur,
      total_invites_sent: Invite.count,
      average_invites_per_bet: Invite.count.to_f / tot_bets,
      total_invites_accepted: Invite.where(status: "accepted").count,
      percent_invites_accepted: Invite.where(status: "accepted").count.to_f / Invite.count * 100,
      total_bets_won_by_owner: total_won,
      percent_bets_won_by_owner: total_won.to_f / tot_bets * 100,
      percent_won_by_type: {
        smoking: Bet.where(status: "won", verb: 'Stop').count.to_f / total_won * 100,
        weight: Bet.where(status: "won", verb: 'Lose').count.to_f / total_won * 100,
        running: Bet.where(status: "won", verb: 'Run').count.to_f / total_won * 100,
        workout: Bet.where(status: "won", verb: 'Workout').count.to_f / total_won * 100,
      }
    }
    render json: report
  end

  private
    def global_password
      unless params[:pw] && params[:pw] == Server::Application.config.pw
        render json: "You don't have access to this data, fool."
      end
    end
end
