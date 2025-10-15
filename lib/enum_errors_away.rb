# frozen_string_literal: true

require 'enum_errors_away/version'
require 'enum_errors_away/railtie' if defined?(Rails)

module EnumErrorsAway # rubocop:todo Style/Documentation
  class << self
    attr_accessor :enabled

    def enabled?
      @enabled != false
    end

    def configure
      yield self
    end
  end
end
