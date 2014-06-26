class UpdatesController < ApplicationController
  before_action :set_update, only: [:show, :edit, :update, :destroy]
  skip_before_action :verify_authenticity_token, only: [:create]

  # GET /updates
  def index
    if params[:bet_id]
      @updates = Bet.find(params[:bet_id]).updates.sort! {|x,y| x.id <=> y.id }
    else
      @updates = []
      @updates = Update.all if params[:pw] && params[:pw] == Server::Application.config.pw
    end
    render 'index.json.jbuilder'
  end

  # GET /updates/1
  def show
    render 'show.json.jbuilder'
  end

  # scaffolding relic
  # GET /updates/new
  def new
    @update = Update.new
  end

  # scaffolding relic
  # GET /updates/1/edit
  def edit
  end

  # POST /updates
  # comes back with the bet that got updated
  def create
    # try to prevent spamming updates
    already_today = false
    updated = false

    # correctness-checking
    render nothing: true if !params[:bet_id]
    return if !params[:bet_id]

    bet = Bet.find(params[:bet_id])
    bet.updates.each do |upd|
      if upd.created_at.to_date == Time.zone.now.to_date
        already_today = true 
	@update = upd
      end
    end
    puts "got here"
    # if they already updated today, just modify that update
    # must allow them to update more than once/day on smoking bets
    if already_today && bet.verb.casecmp('stop').zero?
      @update.update(update_params)
      @bet = Bet.find(params[:bet_id])
      render 'bets/show.json.jbuilder'
      updated = true
    else  # just let them make their update
      @update = Update.new(update_params)

      if @update.save
        @bet = Bet.find(params[:bet_id])
        render 'bets/show.json.jbuilder'
        updated = true
      else
        render json: @update.errors, status: :unprocessable_entity
      end
    end
    if updated
      puts 'trying to push'
      notifs = []
      get_bet_opponents(params[:bet_id]).each do |opponent|
        usr = User.where(fb_id: opponent)
        begin
          notifs.push(APNS::Notification.new(usr.device, alert: 'Your friend updated the bet!', badge: 1, sound: 'default'))
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
        end
      end
      APNS.send_notifications(notifs)
    end
  end

  # PATCH/PUT /updates/1
  def update
    respond_to do |format|
      if @update.update(update_params)
        format.html { redirect_to @update, notice: 'Update was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @update.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /updates/1
  def destroy
    @update.destroy if params[:pw] && params[:pw] == Server::Application.config.pw

    respond_to do |format|
      format.html { redirect_to updates_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_update
      @update = Update.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def update_params
      params.permit(:value, :bet_id, :created_at)
    end
end
