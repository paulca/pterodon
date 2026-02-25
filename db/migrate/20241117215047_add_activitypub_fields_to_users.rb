class AddActivitypubFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :private_key, :text
    add_column :users, :public_key, :text
  end
end
