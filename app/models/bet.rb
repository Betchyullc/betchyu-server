class Bet < ActiveRecord::Base
  has_many :invites
  has_many :updates

  before_save :default_values

  def default_values
    self.received ||= false
    self.paid ||= false
    self.current ||= 0
  end
end
