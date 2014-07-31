class Bet < ActiveRecord::Base
  has_many :invites, :dependent => :destroy
  has_many :updates, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :transactions, :dependent => :destroy

  before_save :default_values
  before_save :checkFinishedOrAccepted

  def default_values
    self.initial ||= 0.0
    self.status ||= "pending"
  end

  def checkFinishedOrAccepted
    self.accepted_at = Time.now if self.status == "accepted"
    self.finished_at = Time.now if self.status == "won" || self.status == "lost"
  end
end
