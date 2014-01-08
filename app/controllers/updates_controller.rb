class UpdatesController < ApplicationController
  before_action :set_update, only: [:show, :edit, :update, :destroy]
  skip_before_action :verify_authenticity_token, only: [:create]

  # GET /updates
  # GET /updates.json
  def index
    if params[:bet_id]
      @updates = Bet.find(params[:bet_id]).updates
    else
      @updates = Update.all
    end
    render 'index.json.jbuilder'
  end

  # GET /updates/1
  # GET /updates/1.json
  def show
    render 'show.json.jbuilder'
  end

  # GET /updates/new
  def new
    @update = Update.new
  end

  # GET /updates/1/edit
  def edit
  end

  # POST /updates
  # POST /updates.json
  def create
    # try to prevent spamming updates
    alreadyToday = false
    return if !params[:bet_id]

    bet = Bet.find(params[:bet_id])
    bet.updates.each do |upd|
      if upd.created_at.to_date == Time.zone.now.to_date
        alreadyToday = true 
	@update = upd
      end
    end
    if alreadyToday && bet.betVerb != 'Stop'
      @update.update(update_params)
      if bet.betVerb != 'Lose'
        bet.current = @update.value
        bet.save
      end
      render 'show.json.jbuilder'
    else
      @update = Update.new(update_params)
      if bet.betVerb != 'Lose'
        bet.current = @update.value
        bet.save
      end

      if @update.save
        render 'show.json.jbuilder'
      else
        render json: @update.errors, status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /updates/1
  # PATCH/PUT /updates/1.json
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
  # DELETE /updates/1.json
  def destroy
    @update.destroy
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
