# frozen_string_literal: true

class Product < ApplicationRecord
  # Test enum with scopes option
  enum :availability, {
    in_stock: 0,
    out_of_stock: 1,
    discontinued: 2
  }, scopes: false

  # Test enum with string values
  enum :category, {
    electronics: 'electronics',
    clothing: 'clothing',
    books: 'books',
    home: 'home'
  }
end
