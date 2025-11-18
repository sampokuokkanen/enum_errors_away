# frozen_string_literal: true

require 'test_helper'

class CreateOrganizations < ActiveRecord::Migration[7.0]
  def change
    create_table :organizations do |t|
      t.string :name
      t.timestamps
    end
  end
end

class EnumErrorsAwayTest < Minitest::Test
  def setup
    ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS organizations')
    CreateOrganizations.new.change
  end

  def teardown
    ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS organizations')
  end

  def test_version_number
    refute_nil ::EnumErrorsAway::VERSION
  end

  def test_enum_works_without_column_when_gem_enabled # rubocop:todo Metrics/MethodLength
    EnumErrorsAway.enabled = true

    # Create a fresh class to avoid conflicts
    test_class = Class.new(ActiveRecord::Base) do
      self.table_name = 'organizations'
    end

    test_class.enum(:mbo_evaluation_create_condition, {
                      never: 0,
                      always: 1,
                      conditional: 2
                    })

    org = test_class.new
    org.mbo_evaluation_create_condition = :always
    assert_equal 'always', org.mbo_evaluation_create_condition
    assert org.always?
  end

  def test_enum_still_works_with_column_present # rubocop:todo Metrics/MethodLength
    EnumErrorsAway.enabled = true

    ActiveRecord::Base.connection.execute(
      'ALTER TABLE organizations ADD COLUMN mbo_evaluation_create_condition INTEGER'
    )

    test_class = Class.new(ActiveRecord::Base) do
      self.table_name = 'organizations'
    end

    test_class.enum(:mbo_evaluation_create_condition, {
                      never: 0,
                      always: 1,
                      conditional: 2
                    })

    org = test_class.create!(name: 'Test Org', mbo_evaluation_create_condition: :conditional)
    assert_equal 'conditional', org.mbo_evaluation_create_condition
    assert org.conditional?
  end

  def test_can_disable_gem
    original_enabled = EnumErrorsAway.enabled?
    EnumErrorsAway.enabled = false

    # When disabled, the gem shouldn't interfere at all
    # This test mainly verifies the enable/disable mechanism works
    refute EnumErrorsAway.enabled?

    # Reset for other tests
    EnumErrorsAway.enabled = original_enabled
  end

  def test_gem_enabled_by_default
    # Reset any previous state
    EnumErrorsAway.enabled = nil
    assert EnumErrorsAway.enabled?
  end

  def test_configure_block
    EnumErrorsAway.configure do |config|
      config.enabled = false
    end

    refute EnumErrorsAway.enabled?

    # Reset for other tests
    EnumErrorsAway.enabled = true
  end

  def test_enum_with_hash_syntax # rubocop:todo Metrics/MethodLength
    EnumErrorsAway.enabled = true

    test_class = Class.new(ActiveRecord::Base) do
      self.table_name = 'organizations'
    end

    test_class.enum(:mbo_evaluation_create_condition, {
                      never: 0,
                      always: 1,
                      conditional: 2
                    })

    org = test_class.new
    org.mbo_evaluation_create_condition = :always
    assert_equal 'always', org.mbo_evaluation_create_condition
  end

  def test_enum_with_options # rubocop:todo Metrics/MethodLength
    EnumErrorsAway.enabled = true

    test_class = Class.new(ActiveRecord::Base) do
      self.table_name = 'organizations'
    end

    test_class.enum(:mbo_evaluation_create_condition, {
                      never: 0,
                      always: 1,
                      conditional: 2
                    }, prefix: true)

    org = test_class.new
    org.mbo_evaluation_create_condition = :always
    assert org.respond_to?(:mbo_evaluation_create_condition_always?)
  end

  def test_enum_method_collision_error_not_suppressed
    EnumErrorsAway.enabled = true

    test_class = Class.new(ActiveRecord::Base) do
      self.table_name = 'organizations'
    end

    # Define first enum with a value that creates a method
    test_class.enum(:status, { available: 0, unavailable: 1 })

    # Try to define second enum that would create a conflicting method
    error = assert_raises(ArgumentError) do
      test_class.enum(:availability, { available: 0, unavailable: 1 })
    end

    # Verify we get the method collision error, not something suppressed
    assert_match(/already defined by another enum/, error.message)
  end

  def test_old_keyword_arg_enum_syntax_still_errors
    EnumErrorsAway.enabled = true

    test_class = Class.new(ActiveRecord::Base) do
      self.table_name = 'organizations'
    end

    # Old deprecated syntax: enum name as keyword argument
    # This should raise an error - the gem should NOT enable this deprecated syntax
    error = assert_raises(ArgumentError) do
      test_class.enum(status: { active: 0, archived: 1 })
    end

    # Verify we get an appropriate error about the deprecated syntax
    assert_match(/wrong number of arguments/, error.message)
  end
end
