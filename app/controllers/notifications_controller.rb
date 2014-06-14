class NotificationsController < ApplicationController
  # kind attribute guide:
  #  1 - rejected invite (data=uid)
  #  2 - accepted invite (data=uid)
  #  3 - won a bet (data=amount)
  #  4 - lost a bet (data=amount)

  before_action :set_notification, only: [:show, :edit, :update, :destroy]
  skip_before_action :verify_authenticity_token, only: [:destroy]

  # GET /notifications
  def index
    if params[:user]
      @notifications = Notification.where(user: params[:user]).to_a
    else
      @notifications = [] # what everyone can see
      @notifications = Notification.all if params[:pw] && params[:pw] == Server::Application.config.pw
    end
    render 'index.json.jbuilder'
  end

  # GET /notifications/1
  def show
  end

  # scaffolding relic
  # GET /notifications/new
  def new
    @notification = Notification.new
  end

  # GET /notifications/1/edit
  def edit
  end

  # POST /notifications
  def create
    @notification = Notification.new(notification_params)

    respond_to do |format|
      if @notification.save
        format.html { redirect_to @notification, notice: 'Notification was successfully created.' }
        format.json { render action: 'show', status: :created, location: @notification }
      else
        format.html { render action: 'new' }
        format.json { render json: @notification.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /notifications/1
  def update
    respond_to do |format|
      if @notification.update(notification_params)
        format.html { redirect_to @notification, notice: 'Notification was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @notification.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /notifications/1
  def destroy
    @notification.destroy 
    head :no_content
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_notification
      @notification = Notification.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def notification_params
      params.permit(:user, :kind, :data)
    end
end
