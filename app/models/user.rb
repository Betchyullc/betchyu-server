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

end
