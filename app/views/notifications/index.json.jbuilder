json.array!(@notifications) do |notification|
  json.extract! notification, :id, :user, :kind, :data
  json.url notification_url(notification, format: :json)
end
