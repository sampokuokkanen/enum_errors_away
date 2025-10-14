class Organization < ApplicationRecord
  # Test enum without a database column - the gem should handle this
  enum :status, {
    active: 0,
    inactive: 1,
    archived: 2
  }

  # Test enum with prefix option
  enum :subscription_tier, {
    free: 0,
    basic: 1,
    premium: 2,
    enterprise: 3
  }, prefix: true
end
