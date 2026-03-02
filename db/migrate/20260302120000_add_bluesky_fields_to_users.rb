class AddBlueskyFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :bsky_handle, :string
    add_column :users, :bsky_app_password, :text
  end
end
