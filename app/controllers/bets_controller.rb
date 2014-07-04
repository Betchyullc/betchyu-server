class BetsController < ApplicationController
  before_action :set_bet, only: [:show, :edit, :update, :destroy]
  before_action :verify_user, except: [:index, :cleanup]
  before_action :prove_user_owns_bet, only: [:destroy, :update]
  before_action :match_uid_and_id, only: [:my_bets, :pending, :friend, :past]
  skip_before_action :verify_authenticity_token, only: [:create, :update, :destroy]

  # GET /bets
  def index
    @bets = [] # set to what everyone can see, then override with what only password people can see
    @bets = Bet.all if params[:pw] && params[:pw] == Server::Application.config.pw
    @bets.sort! {|x,y| x.id <=> y.id }
    render 'index.json.jbuilder'
  end

  # GET /my-bets/:id 
  # returns the list of goals that are still active for a particular user
  def my_bets
    @bets = Bet.where('owner = ? AND status != ? AND status != ?', params[:id], "won", "lost").to_a
    @bets.sort! {|x,y| x.id <=> y.id }
    render 'my-bets.json.jbuilder'
  end
  
  # GET /pending-bets/:id
  def pending
    invList = Invite.where(invitee: params[:id], status: "open").to_a
    @bets = []
    @invs = []
    invList.each do |inv|
      if inv.bet.status != "won" && inv.bet.status != "lost"
        @bets.push inv.bet 
        @invs.push inv
      end
    end
    render 'pending.json.jbuilder'
  end

  # GET /friend-bets/:id
  # gets all the bets which :id is involved in, but does not own.
  # aka, gets all of his friend's bets that he accepted
  def friend
    invs = Invite.where(invitee: params[:id], status: "accepted").to_a
    @bets = []
    invs.each do |inv|
      @bets.push(inv.bet) if inv.bet.status != "won" && inv.bet.status != "lost"
    end
    render 'my-bets.json.jbuilder'
  end

  # GET /past-bets/:id
  # gets all the bets which :id owns, and are either 'won' or 'lost'
  def past
    # make your own past bets
    @bets = Bet.where('owner = ? AND (status = ? OR status = ? )', params[:id], "won", "lost").to_a
    # make the friend's past bets
    invs = Invite.where(invitee: params[:id], status: "accepted").to_a
    @fbets = []
    invs.each do |inv|
      @fbets.push(inv.bet) if inv.bet.status == "won" || inv.bet.status == "lost"
    end
    render 'past.json.jbuilder'
  end

  # GET /achievements-count/:id
  # completed: the number of bets made by the user, that he also won
  # won: the number of bets made by anyone, that he won.
  def achievements_count
    completed_count = Bet.where('owner = ? AND status = ?', params[:id], "won").to_a.count
    invs = Invite.where(invitee: params[:id], status: "accepted").to_a
    won_count = completed_count
    # count all the bets that user accepted, and then the owner failed on
    invs.each do |i|
      won_count += 1 if i.bet.status == 'lost'
    end
    render json: {completed: completed_count, won: won_count}
  end

  # GET /bets/1
  def show
    render 'show.json.jbuilder'
  end

  # GET /bets/new
  # scaffolding relic
  def new
    @bet = Bet.new
  end

  # GET /bets/1/edit
  # scaffolding relic
  def edit
  end

  # POST /bets
  def create
    @bet = Bet.new(bet_params)

    if @bet.save
      render 'show.json.jbuilder'
    else
      render json: @bet.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /bets/1
  # only uses json-style responses
  def update
    if @bet.update(bet_params)
      head :no_content # renders empty response
    else
      render json: @bet.errors, status: :unprocessable_entity
    end
  end

  # DELETE /bets/1
  def destroy
    @bet.transactions.each do |t|
      Braintree::Transaction.void(t.braintree_id)
    end
    @bet.destroy 
    head :no_content
  end

  # called by authorized source to make the server run through all the bets and update the ones that have not had friends accept them
  def cleanup
    if params[:pw] && params[:pw] == Server::Application.config.pw
      num = {killed: 0, finished: 0}
      Bet.all.each do |b|
        end_d = (b.created_at + b.duration).to_time
        expiration = (end_d - b.created_at) / 3 * 86400 #to get seconds
        current = Time.now - b.created_at
        # if the bet has gone more than a third of it's length without being accepted
        if b.status == "pending" && current > expiration
          b.destroy
          num[:killed] += 1
        elsif b.status == "accepted" && Time.now > end_d
          if b.verb != 'Stop'
            finish_bet(b, false)
          else
            finish_bet b
          end
          num[:finished] += 1
        elsif Time.now > (end_d - (60*60*24+60))
          push_notify_user(b.owner, "You are down to your last day. The bet will close at 11:59pm (Eastern Time) tonight!")
        end
      end
      render json: "cleaned #{num[:killed]} and fininshed #{num[:finished]}"
    else
      render nothing: true
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bet
      @bet = Bet.find(params[:id])
    end

    # Never trust parameters from the wild internet, only allow the white list through
    def bet_params
      params.permit(:amount, :noun, :verb, :owner, :stakeAmount, :stakeType, :duration, :initial, :status)
    end

    def prove_user_owns_bet
      render json: "not yours" if @bet.owner != params[:uid]
    end

    def match_uid_and_id
      render json: "not yours" if params[:id] != params[:uid]
    end

    def finish_bet(b, owner_won = true)
      # update the Bet
      b.update(status: owner_won ? "won" : "lost")

      if owner_won
        push_notify_user(params[:user], "You won a bet. You'll recieve your prize soon--and your friends are paying!")

        b.invites.each do |i|
          if i.status = 'accepted'
            result = Braintree::Transaction.sale(
              :amount => b.stakeAmount,
              :customer_id => i.invitee,
              :options => {
                :submit_for_settlement => true
              }
            )
            if result.success?
              # record the transaction in the database
              Transaction.create(braintree_id: result.transaction.id, bet_id: b.id, user: i.invitee, to: params[:user], submitted: true)
              push_notify_user(i.invitee, "You lost a bet. Your card is being charged for the prize.")
            else
              # record the MAJOR ISSUE
              Transaction.create(braintree_id: result.message, bet_id: b.id, user: i.invitee, to: params[:user], submitted: false)
              puts result.message
            end
          end
        end
        render json: "probably ok, bet owner won, and we are submitting a ton (maybe) of transactions"

      else
        push_notify_user(params[:user], "You lost a bet. Your card is being charged for the prize.")

        total = 0
        b.invites.each do |i|
          if i.status == 'accepted'
            total += i.stakeAmount
          end
        end
        result = Braintree::Transaction.sale(
          :amount => total,
          :customer_id => params[:user],
          :options => {
            :submit_for_settlement => true
          }
        )
        if result.success?
          # record the transaction in the database as if it were a bunch of little ones
          b.invites.each do |i|
            if i.status == 'accepted'
              Transaction.create(braintree_id: result.transaction.id, bet_id: b.id, user: params[:user], to: i.invitee, submitted: true)
              push_notify_user(i.invitee, "You won a bet. Your prize is on it's way (courtesy of your friend!)")
            end
          end
          render json: "ok, 'sall good, man. owner lost and paid us one huge(maybe) transaction"
        else
          # record the MAJOR ISSUE
          Transaction.create(braintree_id: result.message, bet_id: b.id, user: params[:user], submitted: false)
          puts result.message
          render json: "WE DID NOT GET MONEY!!! BAD THING!"
        end
      end
    end
end
