require 'test_helper'

class BetsControllerTest < ActionController::TestCase
  setup do
    @bet = bets(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:bets)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create bet" do
    assert_difference('Bet.count') do
      post :create, bet: { betAmount: @bet.betAmount, betNoun: @bet.betNoun, betVerb: @bet.betVerb, endDate: @bet.endDate, opponent: @bet.opponent, opponentStakeAmount: @bet.opponentStakeAmount, opponentStakeType: @bet.opponentStakeType, ownStakeAmount: @bet.ownStakeAmount, ownStakeType: @bet.ownStakeType, owner: @bet.owner }
    end

    assert_redirected_to bet_path(assigns(:bet))
  end

  test "should show bet" do
    get :show, id: @bet
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @bet
    assert_response :success
  end

  test "should update bet" do
    patch :update, id: @bet, bet: { betAmount: @bet.betAmount, betNoun: @bet.betNoun, betVerb: @bet.betVerb, endDate: @bet.endDate, opponent: @bet.opponent, opponentStakeAmount: @bet.opponentStakeAmount, opponentStakeType: @bet.opponentStakeType, ownStakeAmount: @bet.ownStakeAmount, ownStakeType: @bet.ownStakeType, owner: @bet.owner }
    assert_redirected_to bet_path(assigns(:bet))
  end

  test "should destroy bet" do
    assert_difference('Bet.count', -1) do
      delete :destroy, id: @bet
    end

    assert_redirected_to bets_path
  end
end
