class AddActivityPubFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :private_key, :text
    add_column :users, :public_key, :text
    add_column :users, :username, :string
    add_index :users, :username, unique: true
  end
end 