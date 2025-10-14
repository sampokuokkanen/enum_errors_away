require "enum_errors_away/version"
require "enum_errors_away/railtie" if defined?(Rails)

module EnumErrorsAway
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