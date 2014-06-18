json.array!(@bets) do |bet|
  json.extract! bet, :id, :verb, :amount, :noun, :duration, :owner, :stakeAmount, :stakeType, :initial, :status, :created_at, :updated_at

  p = 0 # percent complete
  bet.updates.each do |u|
    p = p + u.value
  end
  tp = (bet.initial + p) / (bet.initial + bet.amount) * 100 
  tp =  (bet.updates.last.value / bet.amount * 100).to_i if bet.verb == 'Lose' && bet.updates.last
  tp = bet.updates.count*100 / bet.duration if bet.noun.downcase == 'smoking'
  json.progress tp.to_i

  opps = []
  bet.invites.each do |i|
    opps.push i.invitee if i.status == "accepted"
  end
  json.opponents opps

  json.url bet_url(bet, format: :json)
end
