module EnumErrorsAway
  module ActiveRecordExtension
    extend ActiveSupport::Concern

    class_methods do
      def enum(name, values = nil, **options)
        return super(name, values, **options) unless EnumErrorsAway.enabled?

        # Extract enum definitions based on Rails 8 signature: enum(name, values = nil, **options)
        definitions = {}
        if values.nil? && options.any?
          # enum(:status, active: 0, archived: 1) syntax
          definitions = { name => options.except(:prefix, :suffix, :scopes, :validate, :default, :_prefix, :_suffix, :_scopes, :_validate, :_default) }
        elsif values.is_a?(Hash)
          # enum(:status, { active: 0, archived: 1 }) syntax
          definitions = { name => values }
        elsif values.is_a?(Array)
          # enum(:status, [:active, :archived]) syntax
          definitions = { name => values }
        else
          # Fallback - shouldn't happen but just in case
          definitions = { name => values }
        end

        # Pre-declare attributes for enum names that don't exist as columns
        definitions.each do |enum_name, enum_values|
          next if enum_name.nil? || enum_name.to_s.empty?
          next if enum_values.nil?

          begin
            enum_name_str = enum_name.to_s
            if !attribute_types.key?(enum_name_str) && !columns_hash.key?(enum_name_str)
              attribute enum_name, :integer
            end
          rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished
            # Ignore database errors during schema introspection
          end
        end

        # Call the original enum method
        begin
          super(name, values, **options)
        rescue ArgumentError => e
          if e.message.include?("Undeclared attribute type for enum")
            # Fallback: declare missing attributes and retry
            definitions.each do |enum_name, enum_values|
              next if enum_name.nil? || enum_name.to_s.empty?
              next if enum_values.nil?

              enum_name_str = enum_name.to_s
              unless attribute_types.key?(enum_name_str)
                attribute enum_name, :integer
              end
            end
            super(name, values, **options)
          else
            raise e
          end
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.include(EnumErrorsAway::ActiveRecordExtension)
end