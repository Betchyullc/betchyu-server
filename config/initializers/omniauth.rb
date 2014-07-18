if Rails.env.production?
  ENV['FACEBOOK_KEY'] = "754096961273788"
  ENV['FACEBOOK_SECRET'] = "2ab02861b58012daafb560422520c10f"
else
  ENV['FACEBOOK_KEY'] = "754096961273788"
  ENV['FACEBOOK_SECRET'] = "2ab02861b58012daafb560422520c10f"
end

OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET'],
           :scope => 'public_profile,user_friends', :provider_ignores_state => true
end
