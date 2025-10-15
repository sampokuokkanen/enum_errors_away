# EnumErrorsAway

[![CI](https://github.com/yourusername/enum_errors_away/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/enum_errors_away/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/enum_errors_away.svg)](https://badge.fury.io/rb/enum_errors_away)

**Fix Rails 7.2+ enum migration failures** - EnumErrorsAway eliminates "Undeclared attribute type for enum" errors that break migrations when enum columns are added in separate migrations.

## The Problem

Rails 7.2+ requires enum attributes to be declared with a type when they don't have a corresponding database column. This causes migration failures in a common scenario:

```ruby
# Your model defines multiple enums
class Organization < ApplicationRecord
  enum status: { active: 0, inactive: 1 }
  enum billing_plan: { free: 0, paid: 1 }
end

# db/migrate/20240101_add_status_to_organizations.rb
add_column :organizations, :status, :integer

# db/migrate/20240201_add_billing_plan_to_organizations.rb
add_column :organizations, :billing_plan, :integer
```

**When running migrations from scratch**, the first migration fails:

```
ArgumentError: Undeclared attribute type for enum 'billing_plan' in Organization.
Enums must be backed by a database column or declared with an explicit type via `attribute`.
```

This happens because:
1. The first migration runs and loads the Organization model
2. The model defines both `status` AND `billing_plan` enums
3. But the `billing_plan` column doesn't exist yet (it's added in the second migration)
4. Rails 7.2+ throws an error

This is especially problematic when:
- **Running migrations from scratch** (new development environments, CI/CD, test databases)
- **Adding new enums over time** in separate migrations
- **Migrating legacy applications** to Rails 7.2+
- **Working with large teams** where different developers add enums in different migrations

## The Solution

EnumErrorsAway automatically handles this for you. Just add the gem and your enums work again - no code changes required!

The gem:
- ✅ **Automatically declares missing enum attributes** as integers
- ✅ **Preserves legitimate enum errors** (method collisions, invalid values, etc.)
- ✅ **Zero configuration required** - works out of the box
- ✅ **Type-safe** - includes RBS type definitions for Steep/TypeProf
- ✅ **Fully tested** - comprehensive test suite
- ✅ **Rails 6.0+ compatible**

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'enum_errors_away'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install enum_errors_away
```

## Usage

Once installed, the gem automatically works for all ActiveRecord models. No configuration needed!

### Before (Rails 7.2+ without this gem):
```ruby
class Organization < ApplicationRecord
  enum status: { active: 0, inactive: 1 }           # Added in first migration
  enum billing_plan: { free: 0, paid: 1 }            # Added in second migration
end

# Running the first migration fails because billing_plan column doesn't exist yet!
# You'd need to manually add: attribute :billing_plan, :integer
```

### After (with this gem):
```ruby
class Organization < ApplicationRecord
  enum status: { active: 0, inactive: 1 }
  enum billing_plan: { free: 0, paid: 1 }
end

# Migrations run successfully - attributes are automatically declared as integers
# No manual attribute declarations needed!
```

## Features

### All Enum Syntaxes Supported

```ruby
class User < ApplicationRecord
  # Hash syntax
  enum status: { active: 0, inactive: 1 }

  # Array syntax
  enum role: [:admin, :user, :guest]

  # With options
  enum access_level: { basic: 0, premium: 1 }, prefix: true

  # Rails 7+ syntax
  enum visibility: { public: 0, private: 1 }, scopes: false
end
```

### Legitimate Errors Still Raised

The gem **only suppresses** the "Undeclared attribute type" error. Other enum errors are preserved:

```ruby
class Organization < ApplicationRecord
  enum status: { available: 0, unavailable: 1 }

  # This will correctly raise an error about method collision
  enum availability: { available: 0, unavailable: 1 }
  # ArgumentError: already defined by another enum
end
```

### Type Safety with RBS

The gem includes RBS type definitions for Steep and TypeProf:

```ruby
# Your types are automatically available
module EnumErrorsAway
  def self.enabled?: () -> bool
  def self.configure: () { (singleton(EnumErrorsAway)) -> void } -> void
end
```

## Configuration

### Disabling the Gem

You can disable the gem globally or conditionally:

```ruby
# config/initializers/enum_errors_away.rb
EnumErrorsAway.configure do |config|
  config.enabled = false
end

# Or conditionally
EnumErrorsAway.enabled = Rails.env.production?
```

### Checking Status

```ruby
EnumErrorsAway.enabled?  # => true
```

## Real-World Example

Here's the typical scenario this gem solves:

```ruby
# app/models/organization.rb
class Organization < ApplicationRecord
  enum status: { active: 0, inactive: 1 }        # Added May 2024
  enum billing_plan: { free: 0, paid: 1 }        # Added June 2024
  enum notification_preference: { email: 0, sms: 1, both: 2 }  # Added July 2024
end

# db/migrate/20240501_add_status_to_organizations.rb
class AddStatusToOrganizations < ActiveRecord::Migration[7.2]
  def change
    add_column :organizations, :status, :integer, default: 0
  end
end

# db/migrate/20240601_add_billing_plan_to_organizations.rb
class AddBillingPlanToOrganizations < ActiveRecord::Migration[7.2]
  def change
    add_column :organizations, :billing_plan, :integer, default: 0
  end
end

# db/migrate/20240701_add_notification_preference_to_organizations.rb
class AddNotificationPreferenceToOrganizations < ActiveRecord::Migration[7.2]
  def change
    add_column :organizations, :notification_preference, :integer, default: 0
  end
end
```

**Without this gem**: When a new developer runs `rails db:migrate` from scratch, the first migration fails because the model references enums that don't have columns yet.

**With this gem**: All migrations run successfully. The gem automatically declares the missing enum attributes, and everything works seamlessly.

## How It Works

1. **Hooks into ActiveRecord** - Uses a Railtie to integrate with Rails initialization
2. **Extends enum method** - Wraps the standard `enum` method via `ActiveSupport::Concern`
3. **Pre-declares attributes** - Before defining an enum, checks if the attribute exists in the database; if not, declares it as `:integer`
4. **Handles migration timing** - Gracefully handles database connection errors during migrations
5. **Preserves error handling** - Only catches "Undeclared attribute type" errors; all other enum errors pass through
6. **Zero runtime performance impact** - Only runs during class definition, not during model usage

## Compatibility

- **Ruby**: 3.1+
- **Rails**: 6.0+
- **Recommended**: Rails 7.2+ (where this problem is most common)

## Development

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rake test

# Run type checks
bundle exec steep check
```

## Testing

The gem includes a comprehensive test suite covering:
- Enums without database columns
- Enums with database columns
- Multiple enum syntaxes (hash, array, with options)
- Error handling (ensures legitimate errors aren't suppressed)
- Configuration and enable/disable functionality
- Integration with real Rails models

Run tests with:
```bash
bundle exec rake test
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/enum_errors_away.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Credits

Created to solve the Rails 7.2+ enum declaration requirement while maintaining backward compatibility with existing codebases.