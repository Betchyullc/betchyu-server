class UserController < ApplicationController

  skip_before_action :verify_authenticity_token, only: [:card]

  # checks to see if any database entries concerning the user :id
  #  exist, in order to return true/false, so that the app knows if the user is new or not
  def show
    id = params[:id]    # convinience caching
    @user = {:id => id, :has_acted => false}    # create the user obj
    # if the user has acted
    @user[:has_acted] = true if Bet.where('owner = ? OR opponent = ?', id, id).to_a.count > 0
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
    trans = Transaction.new({
      :braintree_id => result.transaction.id, 
      :user => params[:user],
      :bet => nil    # uhhh how we gonna know the bet id doesnt exist yet?!!!?!?!?!?
    })
    trans.save

    if result.success?
      render json: {msg:"good"}
    else
      puts result.errors
      puts result.params
      render json: {msg:result.message}
    end
  end
end
