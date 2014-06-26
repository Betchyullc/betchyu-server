class UserController < ApplicationController

  skip_before_action :verify_authenticity_token, only: [:card, :pay, :create]

  # checks to see if any database entries concerning the user :id
  #  exist, in order to return true/false, so that the app knows if the user is new or not
  def show
    id = params[:id]    # convinience caching
    @user = {:id => id, :has_acted => false}    # create the user obj
    # if the user has acted
    @user[:has_acted] = true if Transaction.where(user: id).to_a.count > 0
    @user[:has_acted] = true if Invite.where('invitee = ? AND status != ?', id, "open").to_a.count > 0
    render 'show.json.jbuilder'
  end

  # validates the attached (from POST) card info via BrainTree servers, but DOES NOT
  #  make a transaction
  def card
    is_new_bet = params[:bet_id] == nil
    if is_new_bet
      result = nil
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
      end
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
    end

    if result.success?
      # store the id of the Braintree transaction in our database
      trans = Transaction.new({
        :braintree_id => result.transaction.id, 
        :user => params[:user],
        :bet => params[:bet_id] ? Bet.find(params[:bet_id]) : nil    # nil is a keyword that lets POST /bets know that it needs to update the transaction with the bet_id
             # we will get params[:bet_id] when the user is accepting an offered bet
      })
      trans.save
      render json: {msg:"Card is approved"}
    else
      puts result.message
      puts result.params
      render json: {msg:result.message}
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
        end
        render json: "no charge"
        return
      end
      # notify the owner that he won/lost

      results = [] # what we render in response
      num_submitted = 0
      # loop through them all, voiding and submitting as necessary
      t_arr.each do |t|
        unless t.submitted == true # somehow, this already got done, so we move along.
	  owners_trans = t.user == params[:user]
	  # determine if this trans is the winner's or the loser's
          if (owner_won && owners_trans) || (!owner_won && !owners_trans)
	    # just void the transaction
            results.push Braintree::Transaction.void(t.braintree_id)
	  elsif num_submitted < opps.count # this transaction needs to be submitted for payment
            result = Braintree::Transaction.submit_for_settlement(t.braintree_id)
            if result.success? # transaction successfully submitted for settlement
              num_submitted += 1
              t.update(submitted: true)
              # notify_of_bet_finish(b, params[:user], result.transaction.amount)
              results.push result
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

  #POST /user
  def create
    @user = User.new(user_params)

    if @user.save
      render 'show.json.jbuilder'
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  private


    # b = the Bet, u = UserID string, a = result.transaction.amount
    # simple logic switch on who gets the winning msg and who gets the losing msg
    def notify_of_bet_finish(b,u,a)
      if b.owner == u
        Notification.new({
          user: b.opponent,
          kind: 3, # winning notification
          data: a
        }).save
        Notification.new({
          user: b.owner,
          kind: 4, # losing notification
          data: a
        }).save
      else
        Notification.new({
          user: b.opponent,
          kind: 4, # losing notification
          data: a
        }).save
        Notification.new({
          user: b.owner,
          kind: 3, # winning notification
          data: a
        }).save
      end
    end

    def user_params
      params.permit(:fb_id, :device)
    end

end
