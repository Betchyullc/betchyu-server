json.array!(@bets) do |bet|
  json.extract! bet, :id, :verb, :amount, :noun, :duration, :owner, :stakeAmount, :stakeType, :initial, :status, :created_at, :updated_at
  p = 0 
  @invs.each do |i|
    p = i.id if i.bet.id == bet.id
  end
  json.invite p
  json.url bet_url(bet, format: :json)
end
