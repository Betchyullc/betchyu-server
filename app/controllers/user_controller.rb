class UserController < ApplicationController

  skip_before_action :verify_authenticity_token, only: [:card, :pay]

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
      trans = Transaction.new({
        :braintree_id => result.transaction.id, 
        :user => params[:user],
        :bet => params[:bet_id] ? Bet.find(params[:bet_id]) : nil    # nil is a keyword that lets POST /bets know that it needs to update the transaction with the bet_id
             # we will get params[:bet_id] when the user is accepting an offered bet
      })
      trans.save
      render json: {msg:"Card is approved"}
    else
      puts result.errors
      puts result.params
      render json: {msg:result.message}
    end
  end

  # given a bet_id and a user and a win flag, submits the winner(s)'s Transaction(s)
  #  to Braintree, and voids the Transaction(s) of the loser(s)
  # MONEY CHANGES HANDS (probably)
  def pay
    if params[:bet_id] && params[:user]
      t = Transaction.where(bet_id: params[:bet_id], user: params[:user]).first
      unless t.submitted == true
        result = Braintree::Transaction.submit_for_settlement(t.braintree_id)
        if result.success? # transaction successfully submitted for settlement
          # update our version of the Transaction
          t.submitted = true
          t.save
          # update the Bet this Transaction is related to
          b = Bet.find(params[:bet_id])
          b.finished = true
          b.save
          # make a notification for the winner (the user != params[:user])
          #  and one for the loser (the other of opponent/owner)
          notify_of_bet_finish(b, params[:user], result.transaction.amount)
          # clean up the other Transactions, both on Braintree, and with us.
          Transaction.where(bet_id: params[:bet_id]).to_a.each do |trans|
            if trans.submitted != true
              Braintree::Transaction.void(trans.braintree_id)
              Transaction.destroy(trans.id)
            end
          end
          render json: result
        else
          p result.errors
          render json: result.errors
        end
      end
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

end
