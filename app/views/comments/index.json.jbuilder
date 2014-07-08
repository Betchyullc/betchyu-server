json.array!(@comments) do |comment|
  json.extract! comment, :id, :user_id, :bet_id, :text
  json.user_fb_id comment.user.fb_id  if comment.user
  json.url comment_url(comment, format: :json)
end
