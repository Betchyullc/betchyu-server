class BetsController < ApplicationController
  before_action :set_bet, only: [:show, :edit, :update, :destroy]
  skip_before_action :verify_authenticity_token, only: [:create, :update]

  # GET /bets
  # GET /bets.json
  def index
    rendered = false
    if params[:restriction] && params[:user]
      if params[:restriction].include? "ongoingBets"
        @bets = Bet.where(opponent: params[:user], finished: false).to_a
	@bets = excludeFinished(false)
	if params[:restriction].include? "openBets"
	  invList = Invite.where("invitee = ?", params[:user]).to_a
	  @openBets = []
	  invList.each do |inv|
	    @openBets.push inv.bet if inv.status == "open"
	  end
	  rendered = true
	  render 'myBets.json.jbuilder'
	end
      end
    else
      @bets = [] # set to what everyone can see, then override with what only password people can see
      @bets = Bet.all if params[:pw] && params[:pw] == Server::Application.config.pw
    end
    @bets.sort! {|x,y| x.id <=> y.id }
    render 'index.json.jbuilder' unless rendered
  end

  # GET /goals/697540098 
  # returns the list of goals that are still active for a particular user
  def goals
    @bets = Bet.where(owner: params[:id], finished: false).to_a
    @bets = excludeFinished
    @bets.sort! {|x,y| x.id <=> y.id }
    render 'index.json.jbuilder'
  end

  # GET /achievements-count/:id
  # returns the count of the achieved goals for a given user
  def achievements_count
    @bets = Bet.where(owner: params[:id], finished: true).to_a
    count = {count: 0}
    @bets.each do |bet|
      count[:count] = count[:count] + 1 if bet.betAmount <= bet.current
    end
    render json: count
  end

  # GET /bets/1
  # GET /bets/1.json
  def show
    if params[:reject]
      @bet.invites.each do |inv|
        if inv.invitee == params[:reject]
	  inv.status = "rejected"
          inv.save
	  Notification.new({
	    :user => @bet.owner,
	    :kind => 1,
	    :data => params[:reject]
	  }).save
	end
      end
    end
    render 'show.json.jbuilder'
  end

  # GET /bets/new
  def new
    @bet = Bet.new
  end

  # GET /bets/1/edit
  def edit
  end

  # POST /bets
  # POST /bets.json
  def create
    @bet = Bet.new(bet_params)

    if @bet.save
      # this stuff is to update the transaction to know about this bet id
      t = nil
      Transaction.where(user: @bet.owner).to_a.each do |trans|
        t = trans if trans.bet_id == nil
      end
      t.bet_id = @bet.id
      t.save

      # then we render like normal
      render 'show.json.jbuilder'
    else
      render json: @bet.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /bets/1
  # PATCH/PUT /bets/1.json
  def update
    if params[:opponent]
      @bet.invites.each do |inv|
        if inv.invitee == params[:opponent]
	  inv.status = "accepted"
	  Notification.new({
	    :user => @bet.owner,
	    :kind => 2,
	    :data => params[:opponent]
	  }).save
	else
	  inv.status = "blocked" unless inv.status == "rejected"
	end
        inv.save
      end
    end
    if @bet.update(bet_params)
      head :no_content
    else
      render json: @bet.errors, status: :unprocessable_entity
    end
  end

  # DELETE /bets/1
  # DELETE /bets/1.json
  def destroy
    @bet.destroy
    respond_to do |format|
      format.html { redirect_to bets_url }
      format.json { head :no_content }
    end
  end

  # called by authorized source to make the server run through all the bets and update the ones that have not had friends accept them
  def cleanup
    if params[:pw] && params[:pw] == Server::Application.config.pw
      Bet.all.each do |b|
        bet_accepted = false
        b.invites.each do |i|
          bet_accepted = true if i.status == "accepted"
        end
        expiration = (b.endDate.to_time - b.created_at) / 3
        current = Time.now - b.created_at
        # if the bet has gone more than a third of it's length without being accepted
        if bet_accepted == false && current > expiration
          b.destroy
        end
      end
      render json: "cleaned"
    else
      render nothing: true
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bet
      @bet = Bet.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def bet_params
      params.permit(:betAmount, :betNoun, :betVerb, :endDate, :opponent, :opponentStakeAmount, :opponentStakeType, :owner, :ownStakeAmount, :ownStakeType, :current, :paid, :received)
    end

    # removes from @bets thse bets which are finished, a rather fluid thing
    def excludeFinished(ownBet = true)
      if ownBet
	return @bets.select do |b|
          if b.finished   # this is true when the payment has been submitted for settlement
            false         # false means exclude the damn thing
	  elsif b.betVerb == "Lose"
	    if b.updates.last && b.updates.last.value <= (b.current-b.betAmount)
	      b.received != true
	    else
	      b.paid != true
	    end
	  elsif b.betVerb == "Stop"
	    if b.current == 0
	      b.paid != true
	    else
	      b.received != true
	    end
	  elsif (b.current && b.current < b.betAmount) || !b.current
	    b.paid != true
	  else
	    b.received != true
	  end
	end
      else  # the opponent's version
	return @bets.select do |b|
          if b.finished
            false
	  elsif b.betVerb == "Lose"
	    if b.updates.last && b.updates.last.value <= (b.current-b.betAmount)
	      b.paid != true
	    else
	      b.received != true
	    end
	  elsif b.betVerb == "Stop"
	    if b.current == 0
	      b.received != true
	    else
	      b.paid != true
	    end
	  elsif (b.current && b.current < b.betAmount) || !b.current
	    b.received != true
	  else
	    b.paid != true
	  end
	end
      end
    end
end
