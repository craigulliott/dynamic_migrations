RSpec::Matchers.define :executed_sql do |expected_sqls|
  def sanitize_sqls sqls
    # if a single expected SQL is provided, then convert it to an
    # array to simplify the logic below
    sqls = [sqls] unless sqls.is_a? Array
    # remove any empty lines, as this causes issues with the comparison
    # due to most editors automatically removing trailing whitespace from lines
    sqls.map { |sql| sql.gsub(/^\s*\n/, "") }
    # remove trailing whitespace from each line
    sqls.map { |sql| sql.gsub(/\s+$/, "") }
  end

  match do |migration_object|
    expected_sqls = [expected_sqls] unless expected_sqls.is_a? Array
    # assert all the executed SQLs match the expected SQLs
    expect(sanitize_sqls(migration_object.sqls)).to eql sanitize_sqls(expected_sqls)
  end

  failure_message do |migration_object|
    <<~ERROR
      Expected Migration to have executed:
      #{sanitize_sqls(expected_sqls).join("\n")}
      but it executed:
      #{sanitize_sqls(migration_object.sqls).join("\n")}
    ERROR
  end

  failure_message_when_negated do |migration_object|
    <<~ERROR
      Expected Migration to not have executed:
      #{sanitize_sqls(expected_sqls).join("\n")}
      but it executed:
      #{sanitize_sqls(migration_object.sqls).join("\n")}
    ERROR
  end
end
