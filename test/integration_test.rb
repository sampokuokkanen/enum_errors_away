# frozen_string_literal: true

require 'test_helper'

class IntegrationTest < ActiveSupport::TestCase # rubocop:todo Metrics/ClassLength
  def setup # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    # Create tables for testing
    ActiveRecord::Schema.define do
      create_table :organizations, force: true do |t|
        t.string :name
        t.integer :status # Column exists for persistence and scopes
        t.integer :subscription_tier # Column exists for persistence
        t.timestamps
      end

      create_table :users, force: true do |t|
        t.string :name
        t.string :email
        t.integer :role # Column exists for persistence
        t.integer :notification_preference # Column exists for persistence
        t.integer :account_status # Column exists for persistence
        t.timestamps
      end

      create_table :products, force: true do |t|
        t.string :name
        t.decimal :price, precision: 10, scale: 2
        t.integer :availability # Column exists for persistence
        t.string :category # String column for string enum values
        t.timestamps
      end
    end

    # Clear any existing data
    [Organization, User, Product].each(&:delete_all)
  end

  def teardown
    # Clean up
    [Organization, User, Product].each(&:delete_all)
  end

  # Organization model tests
  test 'organization can use enum without database column' do
    org = Organization.create!(name: 'Test Org')

    # Test setting enum values
    org.status = :active
    assert_equal 'active', org.status
    assert org.active?

    org.status = :archived
    assert_equal 'archived', org.status
    assert org.archived?
    refute org.active?
  end

  test 'organization enum with prefix option works' do
    org = Organization.create!(name: 'Premium Org')

    org.subscription_tier = :premium
    assert_equal 'premium', org.subscription_tier
    assert org.subscription_tier_premium?
    assert_respond_to org, :subscription_tier_free?
    assert_respond_to org, :subscription_tier_enterprise?
  end

  test 'organization can persist enum values' do
    org = Organization.create!(name: 'Persistent Org', status: :inactive)
    assert_equal 'inactive', org.status

    reloaded_org = Organization.find(org.id)
    assert_equal 'inactive', reloaded_org.status
    assert reloaded_org.inactive?
  end

  # User model tests
  test 'user can have multiple enums' do
    user = User.create!(name: 'John', email: 'john@example.com')

    user.role = :admin
    user.notification_preference = :email_only
    user.account_status = :verified

    assert_equal 'admin', user.role
    assert_equal 'email_only', user.notification_preference
    assert_equal 'verified', user.account_status

    assert user.admin?
    assert user.email_only_notification_preference?
    assert user.account_verified?
  end

  test 'user enum with suffix works' do
    user = User.create!(name: 'Jane', email: 'jane@example.com')

    user.notification_preference = :all_notifications
    assert user.all_notifications_notification_preference?
    assert_respond_to user, :none_notification_preference?
  end

  test 'user enum with custom prefix works' do
    user = User.create!(name: 'Bob', email: 'bob@example.com')

    user.account_status = :suspended
    assert user.account_suspended?
    assert_respond_to user, :account_pending?
    assert_respond_to user, :account_verified?
  end

  test 'user can persist multiple enum values' do
    user = User.create!(
      name: 'Alice',
      email: 'alice@example.com',
      role: :member,
      notification_preference: :push_only,
      account_status: :verified
    )

    reloaded_user = User.find(user.id)
    assert_equal 'member', reloaded_user.role
    assert_equal 'push_only', reloaded_user.notification_preference
    assert_equal 'verified', reloaded_user.account_status
  end

  # Product model tests
  test 'product enum with scopes disabled works' do
    product = Product.create!(name: 'Laptop', price: 999.99)

    product.availability = :in_stock
    assert_equal 'in_stock', product.availability
    assert product.in_stock?

    # Verify scopes are disabled (should not respond to scope methods)
    refute_respond_to Product, :in_stock
    refute_respond_to Product, :out_of_stock
  end

  test 'product with existing column still works' do
    # availability column exists in the database
    product = Product.create!(
      name: 'Phone',
      price: 499.99,
      availability: :out_of_stock
    )

    assert_equal 'out_of_stock', product.availability

    reloaded_product = Product.find(product.id)
    assert_equal 'out_of_stock', reloaded_product.availability
    assert reloaded_product.out_of_stock?
  end

  test 'product enum with string values works' do
    product = Product.create!(name: 'Book', price: 19.99)

    product.category = :electronics
    assert_equal 'electronics', product.category
    assert product.electronics?

    product.category = :books
    assert_equal 'books', product.category
    assert product.books?
  end

  # Edge cases and error scenarios
  test 'invalid enum value raises error' do
    org = Organization.new(name: 'Test')

    assert_raises(ArgumentError) do
      org.status = :invalid_status
    end
  end

  test 'enum values can be updated' do
    user = User.create!(name: 'Charlie', email: 'charlie@example.com', role: :guest)
    assert user.guest?

    user.update!(role: :admin)
    assert user.admin?
    refute user.guest?

    reloaded_user = User.find(user.id)
    assert reloaded_user.admin?
  end

  test 'enum works with where queries' do
    User.create!(name: 'Admin 1', email: 'admin1@example.com', role: :admin)
    User.create!(name: 'Admin 2', email: 'admin2@example.com', role: :admin)
    User.create!(name: 'Member 1', email: 'member1@example.com', role: :member)

    admins = User.where(role: :admin)
    assert_equal 2, admins.count
    assert admins.all?(&:admin?)
  end

  test 'enum scopes work when enabled' do
    # Organization model has scopes enabled (default behavior)
    Organization.create!(name: 'Active Org', status: :active)
    Organization.create!(name: 'Inactive Org', status: :inactive)
    Organization.create!(name: 'Another Active', status: :active)

    active_orgs = Organization.active
    assert_equal 2, active_orgs.count
    assert active_orgs.all?(&:active?)
  end

  test 'enum bang methods work' do
    user = User.create!(name: 'Test', email: 'test@example.com', role: :guest)

    assert user.guest?
    user.admin!
    assert user.admin?
    refute user.guest?
  end

  # Configuration tests
  test 'gem can be disabled and re-enabled' do
    original_state = EnumErrorsAway.enabled?

    EnumErrorsAway.enabled = false
    refute EnumErrorsAway.enabled?

    EnumErrorsAway.enabled = true
    assert EnumErrorsAway.enabled?

    EnumErrorsAway.enabled = original_state
  end
end
