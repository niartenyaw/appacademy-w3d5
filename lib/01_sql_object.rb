require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    if instance_variable_defined?(:@columns)
      return instance_variable_get(:@columns)
    end

    table_query = "SELECT * FROM #{self.table_name}"

    table = DBConnection.execute2(table_query)
    column_names = table.first.map(&:to_sym)
    instance_variable_set(:@columns, column_names)
  end

  def self.finalize!
    unless instance_variable_defined?(:@attributes)
      instance_variable_set(:@attributes, Hash.new)
    end

    self.columns.each do |c|

      define_method(c) do
        self.attributes[c]
      end

      define_method("#{c}=") do |value|
        self.attributes[c] = value
      end

    end
  end

  def self.table_name=(table_name)
    instance_variable_set(:@table_name, table_name)
  end

  def self.table_name
    if instance_variable_defined?(:@table_name)
      return instance_variable_get(:@table_name)
    end

    instance_variable_set(:@table_name, self.name.tableize)
  end

  def self.all
    rows = DBConnection.execute("SELECT * FROM #{self.name.tableize}")
    self.parse_all(rows)
  end

  def self.parse_all(results)
    objects = []
    results.each do |row|
      objects << self.new(row)
    end

    objects
  end

  def self.find(id)
    row = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{self.table_name}
      WHERE id = #{id}
    SQL

    return nil if row.empty?
    self.new(row.first)
  end

  def initialize(params = {})
    params.each do |attr_name, v|
      has_column = self.class.columns.include?(attr_name.to_sym)

      raise "unknown attribute '#{attr_name}'" unless has_column

      self.send("#{attr_name.to_sym}=", v)
    end
  end

  def attributes
    if instance_variable_defined?(:@attributes)
      instance_variable_get(:@attributes)
    else
      instance_variable_set(:@attributes, Hash.new)
    end
  end

  def attribute_values
    values = []
    att = instance_variable_get(:@attributes)
    self.class.columns.each do |k|
      values << att[k]
    end

    values
  end

  def insert
    columns = self.class.columns[1..-1]
    values = attribute_values[1..-1].map { |v| v.is_a?(String) ? "\'#{v}\'" : v }

    DBConnection.execute(<<-SQL)
      INSERT INTO
        #{self.class.table_name} (#{columns.join(", ")})
      VALUES
      (#{values.join(", ")})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def stringize(arr)
    arr.map { |v| v.is_a?(String) ? "\'#{v}\'" : v }
  end

  def update
    columns = stringize(self.class.columns[1..-1].map(&:to_s))
    values = stringize(attribute_values[1..-1])
    p setters = columns.zip(values).map { |arr| "#{arr[0]} = #{arr[1]}" }

    DBConnection.execute(<<-SQL)
      UPDATE
        #{self.class.table_name}
      SET
        #{setters.join(", ")}
      WHERE
        id = #{self.id}
    SQL
  end

  def save
    if self.id
      self.update
    else
      self.insert
    end
  end
end
