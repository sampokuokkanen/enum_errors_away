# EnumErrorsAway

[![CI](https://github.com/yourusername/enum_errors_away/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/enum_errors_away/actions/workflows/ci.yml)

A Rails gem that automatically suppresses "Undeclared attribute type for enum" errors by declaring missing enum attributes as integers.

## Problem

Rails 7.2+ requires enum attributes to be explicitly declared with a type when they don't have a corresponding database column. This causes errors like:

```
Undeclared attribute type for enum 'supervisor_auto_setting_method' in Organization. 
Enums must be backed by a database column or declared with an explicit type via `attribute`.
```

## Solution

EnumErrorsAway automatically declares missing enum attributes as integers, eliminating these errors without requiring manual attribute declarations.

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
  # This will raise an error if supervisor_auto_setting_method isn't a database column
  enum supervisor_auto_setting_method: { manual: 0, automatic: 1 }
end
```

### After (with this gem):
```ruby
class Organization < ApplicationRecord
  # Works without errors - attribute is automatically declared as integer
  enum supervisor_auto_setting_method: { manual: 0, automatic: 1 }
end
```

## Configuration

You can disable the gem if needed:

```ruby
# config/initializers/enum_errors_away.rb
EnumErrorsAway.configure do |config|
  config.enabled = false  # Disable the gem
end
```

## How It Works

The gem:
1. Hooks into Rails' ActiveRecord initialization via a Railtie
2. Overrides the `enum` method to catch undeclared attribute errors
3. Automatically declares missing enum attributes as integers
4. Retries the enum declaration with the newly declared attribute

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).