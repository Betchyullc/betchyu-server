json.array!(@bets) do |bet|
  json.extract! bet, :id, :betAmount, :betNoun, :betVerb, :endDate, :opponent, :opponentStakeAmount, :opponentStakeType, :owner, :ownStakeAmount, :ownStakeType, :created_at, :finished, :current
  json.url bet_url(bet, format: :json)
end
