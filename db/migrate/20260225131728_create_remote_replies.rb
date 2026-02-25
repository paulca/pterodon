class CreateRemoteReplies < ActiveRecord::Migration[8.0]
  def change
    create_table :remote_replies do |t|
      t.references :post, null: false, foreign_key: true
      t.string :activity_uri, null: false
      t.string :actor_uri, null: false
      t.string :actor_name
      t.text :content, null: false
      t.datetime :published_at
      t.timestamps
    end

    add_index :remote_replies, :activity_uri, unique: true
  end
end
