class User < ActiveRecord::Base
  has_many :comments, :dependent => :destroy
  before_save :add_password

  def add_password
    raw_pass = self.device + "abc123betchyu" # this random-ness IS our security...
    self.password_hash = BCrypt::Password.create(raw_pass) # use the pass to make hash
  end

  def password
    @password ||= BCrypt::Password.new(self.password_hash)
  end

  def self.from_omniauth(auth)
    where(auth.slice(:provider, :fb_id)).first_or_initialize.tap do |user|
      user.provider = auth.provider
      user.oauth_token = auth.credentials.token
      user.oauth_expires_at = Time.at auth.credentials.expires_at
      user.device = "derp"
      user.fb_id = auth.uid
      user.email = auth.info.email
      user.name = auth.info.name
      user.location = auth.info.location
      user.save!
    end
  end

end
