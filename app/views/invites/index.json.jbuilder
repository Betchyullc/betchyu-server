json.array!(@invites) do |invite|
  json.extract! invite, :id, :status, :invitee, :inviter, :bet_id
  json.url invite_url(invite, format: :json)
end
