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
  def create
    # try to prevent spamming updates
    already_today = false

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
    # if they already updated today, just modify that update
    # must allow them to update more than once/day on smoking bets
    if already_today && bet.verb.casecmp('stop').zero?
      @update.update(update_params)
      render 'show.json.jbuilder'
    else  # just let them make their update
      @update = Update.new(update_params)

      if @update.save
        render 'show.json.jbuilder'
      else
        render json: @update.errors, status: :unprocessable_entity
      end
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
