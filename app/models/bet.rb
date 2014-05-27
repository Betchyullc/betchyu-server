class Bet < ActiveRecord::Base
  has_many :invites, :dependent => :destroy
  has_many :updates, :dependent => :destroy

  before_save :default_values

  def default_values
    self.received ||= false
    self.paid ||= false
    self.finished ||= false
    self.current ||= 0
  end
end
