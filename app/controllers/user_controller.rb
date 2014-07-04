class UserController < ApplicationController

  skip_before_action :verify_authenticity_token, only: [:card, :pay, :create, :update]
  before_action :verify_user, only: [:pay, :update]

  # checks to see if any database entries concerning the user :id
  #  exist, in order to return true/false, so that the app knows if the user is new or not
  def show
    id = params[:id]    # convinience caching
    usr = User.where(fb_id: id).first
    @user = {
      :id => id, 
      :has_acted => false,
      :allow_analytics => usr && usr.allow_analytics ? usr.allow_analytics : false,
      :name => usr && usr.name ? usr.name : "No Name",
      :email => usr && usr.email ? usr.email : "No email given"
    }    # create the user obj
    # if the user has acted
    @user[:has_acted] = true if User.where(fb_id: id).count > 0
    @user[:has_acted] = true if !@user[:has_acted] and Transaction.where(user: id).to_a.count > 0
    @user[:has_acted] = true if !@user[:has_acted] and Invite.where('invitee = ? AND status != ?', id, "open").to_a.count > 0
    render json: @user
  end

  # validates the attached (from POST) card info via BrainTree servers, but DOES NOT
  #  make a transaction
  def card
    # search for a Braintree customer with passed id
    begin
      customer = Braintree::Customer.find(params[:user])
      # if he exists, try to make a new card for him, but jump ship if it was a duplicate
      result = Braintree::CreditCard.create(
        :customer_id => params[:user],
        :number => params[:card_number],
        :cvv => params[:cvv],
        :expiration_month => params[:expiration_month],
        :expiration_year => params[:expiration_year],
        :options => {
          :fail_on_duplicate_payment_method => true,
          :make_default => true,
          :verify_card => true
        }
      )
      if result.success? # this card was new, and passed verification
        render json: {msg: "Card is approved"}
      elsif result.errors.first.code == 81724  || result.message == "Duplicate card exists in the vault."# duplicate code
        render json: {msg: "Card is approved"}
      else
        puts result.errors
        render json: {msg: result.message}
      end
    rescue Braintree::NotFoundError => e
      result = Braintree::Customer.create(
        :id => params[:user],
        :credit_card => {
          :number => params[:card_number],
          :cvv => params[:cvv],
          :expiration_month => params[:expiration_month],
          :expiration_year => params[:expiration_year],
          :options => {
            :verify_card => true
          }
        }
      )
      if result.success?
        render json: {msg: "Card is approved"}
      else
        puts result.errors
        render json: {msg: result.message}
      end
    end
  end

  # given a bet_id and a user and a win flag, submits the winner(s)'s Transaction(s)
  #  to Braintree, and voids the Transaction(s) of the loser(s)
  # calls to this method should only come from the owner of the bet
  # MONEY CHANGES HANDS (probably)
  def pay
    if params[:bet_id] && params[:user] && params[:win]
      owner_won = params[:win].to_s == "true"
      # update the Bet
      b = Bet.find(params[:bet_id])
      b.update(status: owner_won ? "won" : "lost")

      if owner_won
        push_notify_user(params[:user], "You won a bet. You'll recieve your prize soon--and your friends are paying!")

        b.invites.each do |i|
          if i.status == 'accepted'
            result = Braintree::Transaction.sale(
              :amount => b.stakeAmount,
              :customer_id => i.invitee,
              :options => {
                :submit_for_settlement => true
              }
            )
            if result.success?
              # record the transaction in the database
              Transaction.create(braintree_id: result.transaction.id, bet_id: b.id, user: i.invitee, to: params[:user], submitted: true)
              push_notify_user(i.invitee, "You lost a bet. Your card is being charged for the prize.")
            else
              # record the MAJOR ISSUE
              Transaction.create(braintree_id: result.message, bet_id: b.id, user: i.invitee, to: params[:user], submitted: false)
              puts result.message
            end
          end
        end
        render json: "probably ok, bet owner won, and we are submitting a ton (maybe) of transactions"

      else
        push_notify_user(params[:user], "You lost a bet. Your card is being charged for the prize.")

        total = 0
        b.invites.each do |i|
          if i.status == 'accepted'
            total += i.stakeAmount
          end
        end
        result = Braintree::Transaction.sale(
          :amount => total,
          :customer_id => params[:user],
          :options => {
            :submit_for_settlement => true
          }
        )
        if result.success?
          # record the transaction in the database as if it were a bunch of little ones
          b.invites.each do |i|
            if i.status == 'accepted'
              Transaction.create(braintree_id: result.transaction.id, bet_id: b.id, user: params[:user], to: i.invitee, submitted: true)
              push_notify_user(i.invitee, "You won a bet. Your prize is on it's way (courtesy of your friend!)")
            end
          end
          render json: "ok, 'sall good, man. owner lost and paid us one huge(maybe) transaction"
        else
          # record the MAJOR ISSUE
          Transaction.create(braintree_id: result.message, bet_id: b.id, user: params[:user], submitted: false)
          puts result.message
          render json: "WE DID NOT GET MONEY!!! BAD THING!"
        end
      end
    else #bad params
      render json: "death"
    end
  end

  #PUT /user/:id
  def update
    @user = User.where(fb_id: params[:id]).first
    if @user.update(user_params)
      render json: "successful update, sir"
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  #POST /user
  def create
    if User.where(fb_id: params[:fb_id]).to_a.count == 0
      @user = User.new(user_params)

      if @user.save
        render json: "created user #{@user.fb_id}"
      else
        render json: @user.errors, status: :unprocessable_entity
      end
    else 
      if params[:device] && params[:fb_id]
        @user = User.where(fb_id: params[:fb_id]).first
        u_p = user_params
        u_p.delete(:email) if @user.email != nil
        @user.update(u_p) 
      end
      render json: "duplicate user"
    end
  end

  private

    def user_params
      params.permit(:fb_id, :device, :allow_analytics, :name, :is_male, :email, :location)
    end

end
