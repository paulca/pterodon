class EncryptUserPrivateKeys < ActiveRecord::Migration[8.0]
  def up
    # Read plaintext values, then write them back through ActiveRecord encryption.
    # After this migration, User.encrypts :private_key must be declared on the model.
    User.find_each do |user|
      plaintext = user.read_attribute_before_type_cast(:private_key)
      next if plaintext.blank?

      # Skip if already encrypted (starts with ciphertext marker)
      next unless plaintext.start_with?("-----BEGIN")

      # Write the raw ciphertext directly to bypass any model-level encryption
      # that hasn't been declared yet during migration
      ciphertext = ActiveRecord::Encryption::Encryptor.new.encrypt(plaintext)
      user.update_column(:private_key, ciphertext)
    end
  end

  def down
    # Decrypt back to plaintext
    User.find_each do |user|
      raw = user.read_attribute_before_type_cast(:private_key)
      next if raw.blank?

      begin
        plaintext = ActiveRecord::Encryption::Encryptor.new.decrypt(raw)
        user.update_column(:private_key, plaintext)
      rescue ActiveRecord::Encryption::Errors::Decryption
        # Already plaintext, skip
      end
    end
  end
end
