json.array!(@bets) do |bet|
  json.extract! bet, :id, :verb, :amount, :noun, :duration, :owner, :stakeAmount, :stakeType, :initial, :status, :created_at, :updated_at, :accepted_at, :finished_at
  json.url bet_url(bet, format: :json)
end
