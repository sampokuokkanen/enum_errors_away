# frozen_string_literal: true

class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :name
      t.decimal :price, precision: 10, scale: 2
      # Test with one column present and one missing
      t.integer :availability # This one exists in the database
      # category column is missing - gem should handle it
      t.timestamps
    end
  end
end
