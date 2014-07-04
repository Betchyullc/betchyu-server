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
    is_new_bet = params[:bet_id] == nil
    if is_new_bet
      the_msg = "Card is approved"
      params[:opponent_count].to_i.times do
        result = Braintree::Transaction.sale(
          :amount => params[:amount],
          :credit_card => {
            :number => params[:card_number],
            :cvv => params[:cvv],
            :expiration_month => params[:expiration_month],
            :expiration_year => params[:expiration_year]
          }
        )
        if result.success?
          # store the id of the Braintree transaction in our database
          trans = Transaction.create({
            :braintree_id => result.transaction.id, 
            :user => params[:user],
            :bet => params[:bet_id] ? Bet.find(params[:bet_id]) : nil    # nil is a keyword that lets POST /bets know that it needs to update the transaction with the bet_id
                 # we will get params[:bet_id] when the user is accepting an offered bet
          })
        else
          the_message = result.message
        end
      end
      render json: {msg: the_msg}
    else
      result = Braintree::Transaction.sale(
        :amount => params[:amount],
        :credit_card => {
          :number => params[:card_number],
          :cvv => params[:cvv],
          :expiration_month => params[:expiration_month],
          :expiration_year => params[:expiration_year]
        }
      )
      if result.success?
        # store the id of the Braintree transaction in our database
        trans = Transaction.create({
          :braintree_id => result.transaction.id, 
          :user => params[:user],
          :bet => params[:bet_id] ? Bet.find(params[:bet_id]) : nil    # nil is a keyword that lets POST /bets know that it needs to update the transaction with the bet_id
               # we will get params[:bet_id] when the user is accepting an offered bet
        })
        render json: {msg:"Card is approved"}
      else
        puts result.message
        puts result.params
        render json: {msg:result.message}
      end
    end

  end

  # given a bet_id and a user and a win flag, submits the winner(s)'s Transaction(s)
  #  to Braintree, and voids the Transaction(s) of the loser(s)
  # calls to this method should only come from the owner of the bet
  # MONEY CHANGES HANDS (probably)
  def pay
    if params[:bet_id] && params[:user] && params[:win]
      t_arr = Transaction.where(bet_id: params[:bet_id]).to_a # all Trans associated with this Bet, both winners and losers
      owner_won = params[:win].to_s == "true"
      # update the Bet
      Bet.find(params[:bet_id]).update(status: owner_won ? "won" : "lost")

      # don't want to charge people if they had no opponents.
      opps = get_bet_opponents(params[:bet_id])
      if opps.count == 0
        t_arr.each do |t|
          Braintree::Transaction.void(t.braintree_id)
          t.update(submitted: false)
        end
        render json: "no charge"
        return
      end
      # notify the owner that he won/lost
      if owner_won
        push_notify_user(params[:user], "You won a bet. You'll recieve your prize soon--and your friends are paying!")
      else
        push_notify_user(params[:user], "You lost a bet. Your card is being charged for the prize.")
      end

      results = [] # what we render in response
      num_submitted = 0
      # loop through them all, voiding and submitting as necessary
      t_arr.each do |t|
        unless t.submitted == true # somehow, this already got done, so we move along.
       	  owners_trans = t.user == params[:user]
          # notify galore!
          unless owners_trans
            if owner_won
              push_notify_user(t.user, "You lost a bet. Your card is being charged for the prize.")
            else
              push_notify_user(t.user, "You won a bet. Your prize is on it's way (courtesy of your friend!)")
            end
          end
          # determine if this trans is the winner's or the loser's
          if (owner_won && owners_trans) || (!owner_won && !owners_trans)     
          # just void the transaction
            results.push Braintree::Transaction.void(t.braintree_id)
          elsif num_submitted < opps.count # this transaction needs to be submitted for payment
            result = Braintree::Transaction.submit_for_settlement(t.braintree_id)
            if result.success? # transaction successfully submitted for settlement
              t.update(submitted: true, to: owner_won ? params[:user] : opps[num_submitted])
              results.push result
              num_submitted += 1
            else
              p result.errors
              results.push result.errors
            end
          else
	    # just void the transaction
            results.push Braintree::Transaction.void(t.braintree_id)
	  end
	end
      end
      render json: results
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
