class CommentsController < ApplicationController
  before_action :set_comment, only: [:show, :edit, :update, :destroy]
  before_action :verify_user, except: [:index]
  before_action :match_uid_and_user, only: [:destroy]
  skip_before_action :verify_authenticity_token, only: [:create, :update, :destroy]

  # GET /comments
  # GET /comments.json
  def index
    @comments = [] # set to what everyone can see, then override with what only password people can see
    @comments = Bet.find(params[:bet_id]).comments if params[:bet_id]
    @comments = Comment.all if params[:pw] && params[:pw] == Server::Application.config.pw
    @comments.sort! {|x,y| x.id <=> y.id }
    render 'index.json.jbuilder'
  end

  # GET /comments/1
  # GET /comments/1.json
  def show
  end

  # GET /comments/new
  def new
    @comment = Comment.new
  end

  # GET /comments/1/edit
  def edit
  end

  # POST /comments
  # POST /comments.json
  def create
    usr = User.where(fb_id: params[:user_id]).first
    @comment = Comment.new(
      bet_id: params[:bet_id],
      text: params[:text],
      user: usr
    )

    if @comment.save
      # make a list of all possible notification recipients
      list = get_bet_opponents(params[:bet_id])
      list.select! {|uid| uid != params[:user_id]} #filter out the guy who made the notification
      push_notify_users(list, "#{usr.name} commented on #{User.where(fb_id: @comment.bet.owner).first.name}'s bet!")
      push_notify_user(@comment.bet.owner, "#{usr.name} commented on your bet!") unless params[:user_id] == @comment.bet.owner
      render action: 'show', status: :created, location: @comment
    else
      render json: @comment.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /comments/1
  # PATCH/PUT /comments/1.json
  def update
    if @comment.update(comment_params)
      head :no_content
    else
      render json: @comment.errors, status: :unprocessable_entity
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.json
  def destroy
    @comment.destroy
    head :no_content
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_comment
      @comment = Comment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def comment_params
      params.permit(:user_id, :bet_id, :text)
    end

    def match_uid_and_user
      render json: { msg: "you can't see this" } unless params[:uid] && params[:uid] == @comment.user.fb_id
    end
end
