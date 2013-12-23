class BetsController < ApplicationController
  before_action :set_bet, only: [:show, :edit, :update, :destroy]
  skip_before_action :verify_authenticity_token, only: [:create]

  # GET /bets
  # GET /bets.json
  def index
    rendered = false
    if params[:restriction] && params[:user]
      if params[:restriction] == "goals"
        @bets = Bet.find_all_by_owner params[:user]
      elsif params[:restriction].include? "ongoingBets"
        @bets = Bet.find_all_by_opponent params[:user]
	if params[:restriction].include? "openBets"
	  invList = Invite.find_all_by_invitee params[:user]
	  @openBets = []
	  invList.each do |inv|
	    puts inv[:id]
	    @openBets.push inv.bet
	  end
	  rendered = true
	  render 'myBets.json.jbuilder'
	end
      end
    else
      @bets = Bet.all
    end
    render 'index.json.jbuilder' unless rendered
  end

  # GET /bets/1
  # GET /bets/1.json
  def show
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
    respond_to do |format|
      if @bet.update(bet_params)
        format.html { redirect_to @bet, notice: 'Bet was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @bet.errors, status: :unprocessable_entity }
      end
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
      params.permit(:betAmount, :betNoun, :betVerb, :endDate, :opponent, :opponentStakeAmount, :opponentStakeType, :owner, :ownStakeAmount, :ownStakeType, :current)
    end
end
