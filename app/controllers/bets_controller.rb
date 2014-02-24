class BetsController < ApplicationController
  before_action :set_bet, only: [:show, :edit, :update, :destroy]
  skip_before_action :verify_authenticity_token, only: [:create, :update]

  # GET /bets
  # GET /bets.json
  def index
    rendered = false
    if params[:restriction] && params[:user]
      if params[:restriction] == "goals"
        @bets = Bet.where("owner = ?", params[:user]).to_a
	@bets = excludeFinished
      elsif params[:restriction].include? "ongoingBets"
        @bets = Bet.where("opponent = ?", params[:user]).to_a
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
      elsif params[:restriction].include? "completedCount"
        @bets = Bet.find_all_by_owner(params[:user])
	count = {count: 0}
	@bets.each do |bet|
	  count[:count] = count[:count] + 1 if bet.current && bet.betAmount <= bet.current
	end
	rendered = true
	render json: count
      end
    else
      @bets = Bet.all
    end
    @bets.sort! {|x,y| x.id <=> y.id }
    render 'index.json.jbuilder' unless rendered
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bet
      @bet = Bet.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def bet_params
      params.permit(:betAmount, :betNoun, :betVerb, :endDate, :opponent, :opponentStakeAmount, :opponentStakeType, :owner, :ownStakeAmount, :ownStakeType, :current, :paid, :received)
    end

    def excludeFinished(ownBet = true)
      if ownBet
	return @bets.select do |b|
	  if b.betVerb == "Lose"
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
	  if b.betVerb == "Lose"
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
