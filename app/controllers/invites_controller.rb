class InvitesController < ApplicationController
  before_action :set_invite, only: [:show, :edit, :update, :destroy]
  skip_before_action :verify_authenticity_token, only: [:create]

  # GET /invites
  # GET /invites.json
  def index
    rendered = false
    if params[:restriction] && params[:user]
      if params[:restriction] == "count"
        @invites = {
          count: Invite.where(invitee: params[:user], status: "open").to_a.count
        }
        rendered = true
        render json: @invites
      end
    elsif params[:bet_id]
      @invites = Invite.where(bet_id: params[:bet_id]).to_a
    else
      @invites = Invite.all if params[:pw] && params[:pw] == Server::Application.config.pw
    end
    render 'index.json.jbuilder' unless rendered
  end

  # GET /invites/1
  # GET /invites/1.json
  def show
    render 'show.json.jbuilder'
  end

  # GET /invites/new
  def new
    @invite = Invite.new
  end

  # GET /invites/1/edit
  def edit
  end

  # POST /invites
  # POST /invites.json
  def create
    @invite = Invite.new(invite_params)

    if @invite.save
      render 'show.json.jbuilder'
    else
      render json: @invite.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /invites/1
  # PATCH/PUT /invites/1.json
  def update
    respond_to do |format|
      if @invite.update(invite_params)
        format.html { redirect_to @invite, notice: 'Invite was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @invite.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /invites/1
  # DELETE /invites/1.json
  def destroy
    @invite.destroy
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
