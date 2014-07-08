class Comment < ActiveRecord::Base
  belongs_to :bet
  belongs_to :user
end
