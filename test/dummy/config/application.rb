# frozen_string_literal: true

require 'rails/all'
require 'bundler/setup'
Bundler.require(*Rails.groups)
require 'enum_errors_away'

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.active_record.maintain_test_schema = false
    config.secret_key_base = 'test'
    config.root = File.expand_path('..', __dir__)
  end
end
