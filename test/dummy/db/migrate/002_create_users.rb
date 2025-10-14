class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      # Intentionally NOT adding enum columns to test the gem's functionality
      # The gem should automatically handle these:
      # - role (integer)
      # - notification_preference (integer)
      # - account_status (integer)
      t.timestamps
    end
  end
end
