# frozen_string_literal: true

class User < ApplicationRecord
  # Test multiple enums on the same model
  enum :role, {
    guest: 0,
    member: 1,
    admin: 2,
    super_admin: 3
  }

  enum :notification_preference, {
    none: 0,
    email_only: 1,
    push_only: 2,
    all_notifications: 3
  }, suffix: true

  # Test with _prefix and _suffix options
  enum :account_status, {
    pending: 0,
    verified: 1,
    suspended: 2
  }, prefix: :account
end
