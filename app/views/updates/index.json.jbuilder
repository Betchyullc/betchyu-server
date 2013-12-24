json.array!(@updates) do |update|
  json.extract! update, :id, :value, :bet_id, :created_at
  json.url update_url(update, format: :json)
end
