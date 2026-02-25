class CreateRemoteFollowers < ActiveRecord::Migration[8.0]
  def change
    create_table :remote_followers do |t|
      t.references :user, null: false, foreign_key: true
      t.string :actor_uri, null: false
      t.string :inbox_url, null: false
      t.string :shared_inbox_url
      t.timestamps
    end

    add_index :remote_followers, [ :user_id, :actor_uri ], unique: true
  end
end
