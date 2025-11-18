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

        # Pre-declare attributes for enum names that don't exist as columns
        definitions.each do |enum_name, enum_values|
          next if enum_name.nil? || enum_name.to_s.empty?
          next if enum_values.nil?

          begin
            enum_name_str = enum_name.to_s
            # @type var enum_name: Symbol | String
            attribute enum_name, :integer if !attribute_types.key?(enum_name_str) && !columns_hash.key?(enum_name_str)
          rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished
            # Ignore database errors during schema introspection
          end
        end

        # Call the original enum method
        begin
          super(name, values, **options)
        rescue ArgumentError => e
          raise e unless e.message.include?('Undeclared attribute type for enum')

          # Fallback: declare missing attributes and retry
          definitions.each do |enum_name, enum_values|
            next if enum_name.nil? || enum_name.to_s.empty?
            next if enum_values.nil?

            enum_name_str = enum_name.to_s
            # @type var enum_name: Symbol | String
            attribute enum_name, :integer unless attribute_types.key?(enum_name_str)
          end
          super(name, values, **options)
        end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/PerceivedComplexity
    end
  end
end
