class Bet < ActiveRecord::Base
  has_many :invites, :dependent => :destroy
  has_many :updates, :dependent => :destroy
  has_many :transactions, :dependent => :destroy

  before_save :default_values

  def default_values
    self.initial ||= 0.0
    self.status ||= "pending"
  end
end
