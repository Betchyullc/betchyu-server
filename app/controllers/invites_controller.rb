class InvitesController < ApplicationController
  before_action :set_invite, only: [:show, :edit, :update, :destroy]
  before_action :verify_user, only: [:create, :update]
  skip_before_action :verify_authenticity_token, only: [:create, :update]

  # GET /invites
  def index
    rendered = false
    if params[:restriction] && params[:user]
      if params[:restriction] == "count"
        count = {
          count: Invite.where(invitee: params[:user], status: "open").to_a.count
        }
        rendered = true
        render json: count
      end
    elsif params[:bet_id]
      @invites = Invite.where(bet_id: params[:bet_id]).to_a
    else
      @invites = []
      @invites = Invite.all if params[:pw] && params[:pw] == Server::Application.config.pw
    end
    render 'index.json.jbuilder' unless rendered
  end

  # GET /invites/1
  def show
    render 'show.json.jbuilder'
  end

  # GET /invites/new
  # scaffolding relic
  def new
    @invite = Invite.new
  end

  # GET /invites/1/edit
  # scaffolding relic
  def edit
  end

  # POST /invites
  def create
    @invite = Invite.new(invite_params)

    if @invite.save
      render 'show.json.jbuilder'
      push_notify_user(params[:invitee], "A friend invited you to a new Betchyu! See who it is...")
    else
      render json: @invite.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /invites/1
  def update
    if @invite.update(invite_params)
      # make some notificaitons
      if params[:status] == "accepted"
        Notification.new({
          :user => @invite.bet.owner,
          :kind => 2, # bet accepted notification
          :data => params[:name]
        }).save
        # also, gotta change the status of the bet
        @invite.bet.update(status: "accepted")
      elsif params[:status] == "rejected"
        Notification.new({
          :user => @invite.bet.owner,
          :kind => 1, # bet rejected notification
          :data => params[:name]
        }).save
      end

      # respond
      render json: "status updated"
    else
      # error msgs response
      render json: @invite.errors, status: :unprocessable_entity
    end
  end

  # DELETE /invites/1
  def destroy
    @invite.destroy if params[:pw] && params[:pw] == Server::Application.config.pw
    respond_to do |format|
      format.html { redirect_to invites_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_invite
      @invite = Invite.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def invite_params
      params.permit(:status, :invitee, :inviter, :bet_id)
    end
end
