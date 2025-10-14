$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "minitest/reporters"

ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] = File.expand_path("dummy", __dir__)

require File.expand_path("dummy/config/environment.rb", __dir__)
require "rails/test_help"

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]

ActiveRecord::Migration.maintain_test_schema!