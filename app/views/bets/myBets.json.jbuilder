  json.ongoingBets @bets do |bet|
    json.extract! bet, :id, :betAmount, :betNoun, :betVerb, :endDate, :opponent, :opponentStakeAmount, :opponentStakeType, :owner, :ownStakeAmount, :ownStakeType, :created_at
    json.url bet_url(bet, format: :json)
  end 
  json.openBets @openBets do |bet|
    json.extract! bet, :id, :betAmount, :betNoun, :betVerb, :endDate, :opponent, :opponentStakeAmount, :opponentStakeType, :owner, :ownStakeAmount, :ownStakeType, :created_at
    json.url bet_url(bet, format: :json)
  end
