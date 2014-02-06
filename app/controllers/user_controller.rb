class UserController < ApplicationController
  def show
    id = params[:id]    # convinience caching
    @user = {:id => id, :has_acted => false}    # create the user obj
    # if the user has acted
    @user[:has_acted] = true if Bet.where('owner = ? OR opponent = ?', id, id).to_a.count > 0
    render 'show.json.jbuilder'
  end
end
