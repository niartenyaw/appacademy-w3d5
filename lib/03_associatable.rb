require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    if @class_name == "Human"
      "humans"
    else
      @class_name.underscore.downcase.pluralize
    end
  end

  def to_table_name(name)
    if name = "human"
      "humans"
    else
      name.tableize
    end
  end
end

class BelongsToOptions < AssocOptions

  def initialize(name, options = {})
    defaults = {
      primary_key: :id,
      foreign_key: "#{name}_id".to_sym,
      class_name: name.capitalize
    }

    options = defaults.merge(options)

    @primary_key = options[:primary_key]
    @foreign_key = options[:foreign_key]
    @class_name = options[:class_name]

    self.class.send(:define_method, @class_name.downcase) do
      from_table_idx = "#{table_name}.#{options[:primary_key]}"
      to_table_idx = "#{to_table_name(name)}.#{options[:foreign_key]}"

      p from_table_idx
      p to_table_idx
      rows = DBConnection.execute(<<-SQL)
        SELECT
          #{name}.*
        FROM
          #{table_name}
        JOIN
          #{to_table_name(name)} ON #{from_table_idx} = #{to_table_idx}
        WHERE
          #{table_name}.id = #{from_table_idx}
      SQL

      self.parse_all(rows)
    end
    p self.methods
  end



end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      primary_key: :id,
      foreign_key: "#{self_class_name.downcase}_id".to_sym,
      class_name: name.capitalize.singularize
    }

    options = defaults.merge(options)

    @primary_key = options[:primary_key]
    @foreign_key = options[:foreign_key]
    @class_name = options[:class_name]

  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
  end

  def has_many(name, options = {})
    # ...
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end
