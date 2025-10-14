require "rails/railtie"

module EnumErrorsAway
  class Railtie < Rails::Railtie
    initializer "enum_errors_away.suppress_enum_errors", before: "active_record.set_configs" do
      ActiveSupport.on_load(:active_record) do
        require "enum_errors_away/active_record_extension"
      end
    end
  end
end