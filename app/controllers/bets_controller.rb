class BetsController < ApplicationController
  before_action :set_bet, only: [:show, :edit, :update, :destroy]
  skip_before_action :verify_authenticity_token, only: [:create, :update]

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
    render 'index.json.jbuilder'
  end
  
  # GET /pending-bets/:id
  def pending
    invList = Invite.where(invitee: params[:id], status: "open").to_a
    @bets = []
    invList.each do |inv|
      @bets.push inv.bet if inv.bet.status != "won" && inv.bet.status != "lost"
    end
    render 'index.json.jbuilder'
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
    render 'index.json.jbuilder'
  end

  # GET /achievements-count/:id
  # returns the count of the achieved goals for a given user
  def achievements_count
    @bets = Bet.where('owner = ? AND status = ?', params[:id], "won").to_a
    render json: {count: @bets.count}
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
      # this stuff is to update the transaction to know about this bet id
      Transaction.where(user: @bet.owner).to_a.each do |trans|
        if trans.bet_id == nil
          trans.bet_id = @bet.id
          trans.save
        end
      end

      # then we render like normal
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
    @bet.destroy if params[:pw] && params[:pw] == Server::Application.config.pw
    respond_to do |format|
      format.html { redirect_to bets_url }
      format.json { head :no_content }
    end
  end

  # called by authorized source to make the server run through all the bets and update the ones that have not had friends accept them
  def cleanup
    if params[:pw] && params[:pw] == Server::Application.config.pw
      num_killed = 0
      Bet.all.each do |b|
        expiration = (b.endDate.to_time - b.created_at) / 3
        current = Time.now - b.created_at
        # if the bet has gone more than a third of it's length without being accepted
        if b.status == "pending" && current > expiration
          b.destroy
          num_killed += 1
        end
      end
      render json: "cleaned #{num_killed}"
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
end
