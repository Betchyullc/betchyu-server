class AddAllowAnalyticsToUser < ActiveRecord::Migration
  def change
    add_column :users, :allow_analytics, :boolean, default: true
  end
end
