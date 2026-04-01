# frozen_string_literal: true

require 'test_helper'

# Tests for GitHub Issue #1: PostgreSQL native enum columns not handled correctly
#
# The issue: When a model uses a PostgreSQL native enum column (created with `t.enum`),
# the gem incorrectly skips declaring an attribute for it because the column exists.
# However, Rails 8 requires explicit attribute declarations for columns with type :enum.
#
# Current gem logic (line 38 in active_record_extension.rb):
#   next if columns_hash.key?(enum_name_str)
#
# Should be changed to:
#   column = columns_hash[enum_name_str]
#   next if column && column.type != :enum
class PostgresqlNativeEnumTest < ActiveSupport::TestCase
  # ===========================================================================
  # PASSING TESTS - Standard enum use cases that work correctly
  # ===========================================================================

  test 'enum with integer column works and persists' do
    ActiveRecord::Schema.define do
      create_table :posts_int_status, force: true do |t|
        t.string :title
        t.integer :status
        t.timestamps
      end
    end

    klass = Class.new(ApplicationRecord) do
      self.table_name = 'posts_int_status'
      enum :status, { draft: 0, published: 1, archived: 2 }
    end

    post = klass.new(title: 'Test Post')
    post.status = :published
    assert_equal 'published', post.status
    assert post.published?

    post.save!
    reloaded = klass.find(post.id)
    assert_equal 'published', reloaded.status
  end

  test 'enum with string column works and persists' do
    ActiveRecord::Schema.define do
      create_table :posts_str_category, force: true do |t|
        t.string :title
        t.string :category
        t.timestamps
      end
    end

    klass = Class.new(ApplicationRecord) do
      self.table_name = 'posts_str_category'
      enum :category, { tech: 'tech', lifestyle: 'lifestyle', news: 'news' }
    end

    post = klass.new(title: 'Test')
    post.category = :tech
    assert_equal 'tech', post.category
    assert post.tech?

    post.save!
    assert_equal 'tech', klass.find(post.id).category
  end

  test 'enum without database column works in-memory' do
    ActiveRecord::Schema.define do
      create_table :posts_no_column, force: true do |t|
        t.string :title
        t.timestamps
      end
    end

    klass = Class.new(ApplicationRecord) do
      self.table_name = 'posts_no_column'
      enum :status, { draft: 0, published: 1, archived: 2 }
    end

    post = klass.new(title: 'Test')
    post.status = :draft
    assert_equal 'draft', post.status
    assert post.draft?
  end

  test 'gem declares attribute when column does not exist' do
    ActiveRecord::Schema.define do
      create_table :posts_verify_attr, force: true do |t|
        t.string :title
        # No status column
        t.timestamps
      end
    end

    klass = Class.new(ApplicationRecord) do
      self.table_name = 'posts_verify_attr'
    end

    # Before enum declaration, verify status column doesn't exist
    refute klass.columns_hash.key?('status')

    # Track attribute calls WITH A TYPE (the gem passes :integer or :string)
    gem_attribute_calls = []
    original_attribute = klass.method(:attribute)
    klass.define_singleton_method(:attribute) do |name, type = nil, **kwargs|
      gem_attribute_calls << { name: name, type: type } if type
      original_attribute.call(name, type, **kwargs)
    end

    # Declare enum
    klass.enum :status, { draft: 0, published: 1 }

    # Gem SHOULD call attribute with a type when column doesn't exist
    status_calls = gem_attribute_calls.select { |c| c[:name].to_s == 'status' }
    assert_not_empty status_calls,
                     'Gem should declare attribute with type when column does not exist'
  end

  test 'gem correctly skips attribute for existing string column' do
    # This verifies the gem doesn't unnecessarily declare attributes for
    # normal columns that work fine without it.

    ActiveRecord::Schema.define do
      create_table :existing_col, force: true do |t|
        t.string :title
        t.string :status
        t.timestamps
      end
    end

    klass = Class.new(ApplicationRecord) do
      self.table_name = 'existing_col'
    end

    gem_attribute_calls = []
    original_attribute = klass.method(:attribute)
    klass.define_singleton_method(:attribute) do |name, type = nil, **kwargs|
      gem_attribute_calls << { name: name, type: type } if type
      original_attribute.call(name, type, **kwargs)
    end

    klass.enum :status, { draft: 0, published: 1, archived: 2 }

    # Gem should NOT call attribute with type for existing string columns
    status_calls = gem_attribute_calls.select { |c| c[:name].to_s == 'status' }
    assert_empty status_calls,
                 'Gem correctly skips attribute declaration for existing string columns'
  end

  test 'gem correctly skips attribute for existing integer column' do
    ActiveRecord::Schema.define do
      create_table :existing_int_col, force: true do |t|
        t.string :title
        t.integer :status
        t.timestamps
      end
    end

    klass = Class.new(ApplicationRecord) do
      self.table_name = 'existing_int_col'
    end

    gem_attribute_calls = []
    original_attribute = klass.method(:attribute)
    klass.define_singleton_method(:attribute) do |name, type = nil, **kwargs|
      gem_attribute_calls << { name: name, type: type } if type
      original_attribute.call(name, type, **kwargs)
    end

    klass.enum :status, { draft: 0, published: 1, archived: 2 }

    status_calls = gem_attribute_calls.select { |c| c[:name].to_s == 'status' }
    assert_empty status_calls,
                 'Gem correctly skips attribute declaration for existing integer columns'
  end

  test 'enum with prefix option works correctly' do
    ActiveRecord::Schema.define do
      create_table :orders_prefix, force: true do |t|
        t.string :number
        t.integer :payment_status
        t.timestamps
      end
    end

    klass = Class.new(ApplicationRecord) do
      self.table_name = 'orders_prefix'
      enum :payment_status, { pending: 0, completed: 1 }, prefix: true
    end

    order = klass.new(number: 'ORD-001')
    order.payment_status = :completed
    assert order.payment_status_completed?
  end

  test 'multiple enums on same model work' do
    ActiveRecord::Schema.define do
      create_table :articles_multi, force: true do |t|
        t.string :title
        t.integer :status
        t.integer :visibility
        t.timestamps
      end
    end

    klass = Class.new(ApplicationRecord) do
      self.table_name = 'articles_multi'
      enum :status, { draft: 0, published: 1 }
      enum :visibility, { public_vis: 0, private_vis: 1 }, prefix: :vis
    end

    article = klass.new(title: 'Test')
    article.status = :published
    article.visibility = :private_vis

    assert article.published?
    assert article.vis_private_vis?
  end

  # ===========================================================================
  # FAILING TESTS - PostgreSQL native enum columns (Issue #1)
  #
  # These tests FAIL with current code, demonstrating the bug.
  # They assert what SHOULD happen (gem declares attribute for PG enum columns),
  # but currently doesn't.
  #
  # After fixing Issue #1, these tests should PASS.
  # ===========================================================================

  test 'FAILING: gem should declare attribute for PG enum column' do
    # This is the core test for Issue #1.
    # When column.type == :enum (PostgreSQL native enum), the gem SHOULD
    # declare an attribute because Rails 8 requires it.

    ActiveRecord::Schema.define do
      create_table :pg_posts, force: true do |t|
        t.string :title
        t.string :status  # Simulates PG enum (we mock the type)
        t.timestamps
      end
    end

    base_klass = Class.new(ApplicationRecord) do
      self.table_name = 'pg_posts'
    end

    # Mock column to return type :enum (simulating PostgreSQL native enum)
    original_column = base_klass.columns_hash['status']
    enum_column = Class.new(SimpleDelegator) { def type; :enum; end }.new(original_column)

    klass = Class.new(base_klass) do
      define_singleton_method(:columns_hash) do
        super().merge('status' => enum_column)
      end
    end

    # Verify mock works
    assert_equal :enum, klass.columns_hash['status'].type

    # Track attribute calls WITH A TYPE (gem's signature)
    gem_attribute_calls = []
    original_attribute = klass.method(:attribute)
    klass.define_singleton_method(:attribute) do |name, type = nil, **kwargs|
      gem_attribute_calls << { name: name, type: type } if type
      original_attribute.call(name, type, **kwargs)
    end

    klass.enum :status, { draft: 'draft', published: 'published' }

    # EXPECTED: Gem SHOULD call attribute with :string type for PG enum columns
    # ACTUAL (BUG): Gem skips because column exists
    status_calls = gem_attribute_calls.select { |c| c[:name].to_s == 'status' }

    assert_not_empty status_calls,
                     'Gem should declare attribute for PG enum column (column.type == :enum)'
  end

  test 'FAILING: PG enum attribute should be declared with :string type' do
    ActiveRecord::Schema.define do
      create_table :pg_posts2, force: true do |t|
        t.string :title
        t.string :status
        t.timestamps
      end
    end

    base_klass = Class.new(ApplicationRecord) do
      self.table_name = 'pg_posts2'
    end

    original_column = base_klass.columns_hash['status']
    enum_column = Class.new(SimpleDelegator) { def type; :enum; end }.new(original_column)

    klass = Class.new(base_klass) do
      define_singleton_method(:columns_hash) do
        super().merge('status' => enum_column)
      end
    end

    gem_attribute_calls = []
    original_attribute = klass.method(:attribute)
    klass.define_singleton_method(:attribute) do |name, type = nil, **kwargs|
      gem_attribute_calls << { name: name, type: type } if type
      original_attribute.call(name, type, **kwargs)
    end

    # String enum values should result in :string attribute type
    klass.enum :status, { draft: 'draft', published: 'published' }

    status_calls = gem_attribute_calls.select { |c| c[:name].to_s == 'status' }

    # EXPECTED: attribute :status, :string
    assert_not_empty status_calls,
                     'Gem should declare attribute for PG enum column'

    # After fix, uncomment to verify type:
    # assert_equal :string, status_calls.first[:type]
  end

  test 'FAILING: model with mixed PG enum and regular integer columns' do
    ActiveRecord::Schema.define do
      create_table :mixed_model, force: true do |t|
        t.string :title
        t.string :pg_status     # Mocked as PG enum
        t.integer :priority     # Regular integer
        t.timestamps
      end
    end

    base_klass = Class.new(ApplicationRecord) do
      self.table_name = 'mixed_model'
    end

    original_column = base_klass.columns_hash['pg_status']
    enum_column = Class.new(SimpleDelegator) { def type; :enum; end }.new(original_column)

    klass = Class.new(base_klass) do
      define_singleton_method(:columns_hash) do
        super().merge('pg_status' => enum_column)
      end
    end

    gem_attribute_calls = []
    original_attribute = klass.method(:attribute)
    klass.define_singleton_method(:attribute) do |name, type = nil, **kwargs|
      gem_attribute_calls << { name: name, type: type } if type
      original_attribute.call(name, type, **kwargs)
    end

    klass.enum :pg_status, { active: 'active', inactive: 'inactive' }
    klass.enum :priority, { low: 0, medium: 1, high: 2 }, prefix: true

    pg_status_calls = gem_attribute_calls.select { |c| c[:name].to_s == 'pg_status' }
    priority_calls = gem_attribute_calls.select { |c| c[:name].to_s == 'priority' }

    # priority (integer) should NOT have attribute called - this is correct behavior
    assert_empty priority_calls,
                 'priority (integer column) correctly has no gem attribute declaration'

    # pg_status (PG enum) SHOULD have attribute called - this currently fails
    assert_not_empty pg_status_calls,
                     'pg_status (PG enum, column.type == :enum) should have attribute declared'
  end

  test 'FAILING: multiple PG enum columns should all get attributes' do
    ActiveRecord::Schema.define do
      create_table :multi_pg_enum, force: true do |t|
        t.string :title
        t.string :status
        t.string :visibility
        t.timestamps
      end
    end

    base_klass = Class.new(ApplicationRecord) do
      self.table_name = 'multi_pg_enum'
    end

    status_col = base_klass.columns_hash['status']
    vis_col = base_klass.columns_hash['visibility']

    enum_status = Class.new(SimpleDelegator) { def type; :enum; end }.new(status_col)
    enum_vis = Class.new(SimpleDelegator) { def type; :enum; end }.new(vis_col)

    klass = Class.new(base_klass) do
      define_singleton_method(:columns_hash) do
        super().merge('status' => enum_status, 'visibility' => enum_vis)
      end
    end

    gem_attribute_calls = []
    original_attribute = klass.method(:attribute)
    klass.define_singleton_method(:attribute) do |name, type = nil, **kwargs|
      gem_attribute_calls << { name: name, type: type } if type
      original_attribute.call(name, type, **kwargs)
    end

    klass.enum :status, { draft: 'draft', published: 'published' }
    klass.enum :visibility, { public_vis: 'public', private_vis: 'private' }

    status_calls = gem_attribute_calls.select { |c| c[:name].to_s == 'status' }
    vis_calls = gem_attribute_calls.select { |c| c[:name].to_s == 'visibility' }

    # Both should have attribute declared
    assert_not_empty status_calls,
                     'status (PG enum) should have attribute declared'
    assert_not_empty vis_calls,
                     'visibility (PG enum) should have attribute declared'
  end

  test 'FAILING: PG enum with prefix option should work' do
    ActiveRecord::Schema.define do
      create_table :pg_enum_prefix, force: true do |t|
        t.string :name
        t.string :payment_status
        t.timestamps
      end
    end

    base_klass = Class.new(ApplicationRecord) do
      self.table_name = 'pg_enum_prefix'
    end

    original_column = base_klass.columns_hash['payment_status']
    enum_column = Class.new(SimpleDelegator) { def type; :enum; end }.new(original_column)

    klass = Class.new(base_klass) do
      define_singleton_method(:columns_hash) do
        super().merge('payment_status' => enum_column)
      end
    end

    gem_attribute_calls = []
    original_attribute = klass.method(:attribute)
    klass.define_singleton_method(:attribute) do |name, type = nil, **kwargs|
      gem_attribute_calls << { name: name, type: type } if type
      original_attribute.call(name, type, **kwargs)
    end

    klass.enum :payment_status, { pending: 'pending', completed: 'completed' }, prefix: true

    payment_calls = gem_attribute_calls.select { |c| c[:name].to_s == 'payment_status' }

    assert_not_empty payment_calls,
                     'payment_status (PG enum) should have attribute declared'
  end

  test 'FAILING: PG enum with suffix option should work' do
    ActiveRecord::Schema.define do
      create_table :pg_enum_suffix, force: true do |t|
        t.string :name
        t.string :role
        t.timestamps
      end
    end

    base_klass = Class.new(ApplicationRecord) do
      self.table_name = 'pg_enum_suffix'
    end

    original_column = base_klass.columns_hash['role']
    enum_column = Class.new(SimpleDelegator) { def type; :enum; end }.new(original_column)

    klass = Class.new(base_klass) do
      define_singleton_method(:columns_hash) do
        super().merge('role' => enum_column)
      end
    end

    gem_attribute_calls = []
    original_attribute = klass.method(:attribute)
    klass.define_singleton_method(:attribute) do |name, type = nil, **kwargs|
      gem_attribute_calls << { name: name, type: type } if type
      original_attribute.call(name, type, **kwargs)
    end

    klass.enum :role, { admin: 'admin', member: 'member' }, suffix: true

    role_calls = gem_attribute_calls.select { |c| c[:name].to_s == 'role' }

    assert_not_empty role_calls,
                     'role (PG enum) should have attribute declared'
  end
end
