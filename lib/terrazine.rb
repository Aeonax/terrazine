require_relative 'helper.rb'
require_relative 'terrazine/config'
require_relative 'terrazine/builder'
require_relative 'terrazine/constructor'
require_relative 'terrazine/type_map'
require_relative 'terrazine/presenter'
require_relative 'terrazine/result'

module Terrazine

  VERSION = '0.0.1'

  def self.connection
    Config.connection
  end

  def self.config(params)
    Config.set params
  end

  def self.send_request(structure, params = {})
    sql = build_sql structure
    connection = Config.connection!(params[:connection])

    res = time_output(sql) { execute_request connection, sql }
    Result.new res, params
  end

  def self.new_constructor(structure = {})
    Constructor.new structure
  end

  def self.build_sql(structure)
    case structure
    when Hash
      new_constructor(structure).build_sql
    when Constructor
      structure.build_sql
    when String
      structure
    else
      raise # TODO: Errors
    end
  end

  def self.time_output(str = '')
    time = Time.now
    res = yield
    puts "(\033[32m#{(Time.now - time) * 1000})ms \033[34m#{str}\033[0m"
    res
  end

  # TODO: relocate
  def self.execute_request(connection, sql)
    if sql.is_a?(Array)
      connection.exec_params(sql.first, sql.second)
    else
      connection.exec(sql)
    end
  end
end
