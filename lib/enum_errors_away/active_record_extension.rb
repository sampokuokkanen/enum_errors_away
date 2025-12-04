# frozen_string_literal: true

module EnumErrorsAway
  module ActiveRecordExtension # rubocop:todo Style/Documentation
    extend ActiveSupport::Concern

    class_methods do # rubocop:todo Metrics/BlockLength
      # rubocop:todo Metrics/PerceivedComplexity
      # rubocop:todo Metrics/MethodLength
      # rubocop:todo Metrics/AbcSize
      def enum(name, values = nil, **options) # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
        return super(name, values, **options) unless EnumErrorsAway.enabled?

        # Extract enum definitions based on Rails 8 signature: enum(name, values = nil, **options)
        definitions = if values.nil? && options.any?
                        # enum(:status, active: 0, archived: 1) syntax
                        { name => options.except(:prefix, :suffix, :scopes, :validate, :default, :_prefix, :_suffix,
                                                 :_scopes, :_validate, :_default) }
                      elsif values.is_a?(Hash)
                        # enum(:status, { active: 0, archived: 1 }) syntax
                        { name => values }
                      elsif values.is_a?(Array)
                        # enum(:status, [:active, :archived]) syntax
                        { name => values }
                      else
                        # Fallback - shouldn't happen but just in case
                        { name => values }
                      end

        # Pre-declare attributes for enum names that don't have a database column.
        # We check columns_hash to avoid overriding the column's type.
        definitions.each do |enum_name, enum_values|
          next if enum_name.nil? || enum_name.to_s.empty?

          begin
            enum_name_str = enum_name.to_s
            # Only declare attribute if there's no column for it
            next if columns_hash.key?(enum_name_str)

            # Determine attribute type from enum values:
            # - If all values are integers (or array), use :integer
            # - If any value is a string, use :string
            attr_type = if enum_values.is_a?(Array)
                          :integer
                        elsif enum_values.is_a?(Hash) && enum_values.values.any? { |v| v.is_a?(String) }
                          :string
                        else
                          :integer
                        end

            attribute enum_name, attr_type
          rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished
            # Silently ignore database errors - the enum may fail later,
            # but that's the expected behavior without this gem
          end
        end

        # Call the original enum method
        super(name, values, **options)
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/PerceivedComplexity
    end
  end
end
