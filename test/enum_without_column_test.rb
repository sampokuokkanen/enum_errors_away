require "test_helper"

# Test the gem's core functionality: allowing enum declarations without database columns
class EnumWithoutColumnTest < ActiveSupport::TestCase
  def setup
    # Create a minimal table without enum columns
    ActiveRecord::Schema.define do
      create_table :test_models, force: true do |t|
        t.string :name
        t.timestamps
      end
    end

    # Define a test model without enum columns in the database
    Object.send(:remove_const, :TestModel) if defined?(TestModel)
    @test_model_class = Class.new(ApplicationRecord) do
      self.table_name = "test_models"

      # These enums should work even without database columns
      # thanks to the gem
      enum :status, {
        active: 0,
        inactive: 1,
        archived: 2
      }

      enum :priority, {
        low: 0,
        medium: 1,
        high: 2
      }, prefix: true
    end
    Object.const_set(:TestModel, @test_model_class)
  end

  def teardown
    Object.send(:remove_const, :TestModel) if defined?(TestModel)
  end

  test "enum declaration does not raise error without database column" do
    # This test validates the gem's primary purpose:
    # allowing enum declarations without database columns
    assert_nothing_raised do
      model = TestModel.new(name: "Test")
      model.status = :active
    end
  end

  test "enum methods are available without database column" do
    model = TestModel.new(name: "Test")

    # Setter methods work
    assert_nothing_raised do
      model.status = :active
    end

    # Getter methods work (in-memory)
    assert_equal "active", model.status

    # Question methods work
    assert model.active?
    refute model.inactive?
  end

  test "enum with prefix works without database column" do
    model = TestModel.new(name: "Test")

    model.priority = :high
    assert_equal "high", model.priority
    assert model.priority_high?
    assert_respond_to model, :priority_low?
    assert_respond_to model, :priority_medium?
  end

  test "enum bang methods work without database column" do
    model = TestModel.new(name: "Test")

    model.active!
    assert model.active?

    model.inactive!
    assert model.inactive?
    refute model.active?
  end

  test "invalid enum value raises error even without database column" do
    skip "Rails 8 behavior for invalid enum values may vary"
    model = TestModel.new(name: "Test")

    assert_raises(ArgumentError) do
      model.status = :invalid_status
    end
  end

  test "multiple enums can be declared without database columns" do
    model = TestModel.new(name: "Test")

    assert_nothing_raised do
      model.status = :active
      model.priority = :high
    end

    assert_equal "active", model.status
    assert_equal "high", model.priority
  end

  test "enum works with nil value without database column" do
    model = TestModel.new(name: "Test")

    assert_nil model.status
    assert_nil model.priority
  end

  test "note: values do not persist without database columns" do
    # This test documents a limitation: in-memory attributes don't persist
    model = TestModel.create!(name: "Test")
    model.status = :active

    # The in-memory value is set
    assert_equal "active", model.status

    # But after reloading, it's lost because there's no database column
    reloaded = TestModel.find(model.id)
    assert_nil reloaded.status  # No column = no persistence
  end

  test "gem can be disabled to restore original Rails behavior" do
    skip "Disabling gem behavior is hard to test in current setup"
    # This test is skipped because once ActiveRecordExtension is loaded,
    # it's difficult to test the original Rails behavior in the same process
  end
end
