# frozen_string_literal: true

require 'rails/railtie'

module EnumErrorsAway
  class Railtie < Rails::Railtie # rubocop:todo Style/Documentation
    initializer 'enum_errors_away.suppress_enum_errors', before: 'active_record.set_configs' do
      ActiveSupport.on_load(:active_record) do
        require 'enum_errors_away/active_record_extension'
      end
    end
  end
end
