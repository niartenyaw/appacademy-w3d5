require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    params_string = params.map do |arr|
      arr = stringize(arr)
      "#{arr[0][1..-2]} = #{arr[1]}"
    end

    rows = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{self.table_name}
      WHERE #{params_string.join(" AND ")}
    SQL
    p rows
    self.parse_all(rows)
  end

  def stringize(arr)
    arr.map { |v| v.is_a?(String) || v.is_a?(Symbol) ? "\'#{v}\'" : v }
  end

end

class SQLObject
  extend Searchable
end
