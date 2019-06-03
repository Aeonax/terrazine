require_relative 'builders/operators'
require_relative 'builders/predicates'
require_relative 'builders/expressions'
require_relative 'builders/clauses'
require_relative 'builders/params'

module Terrazine
  # builds structures in to sql string
  # TODO: SPLIT!!! But how-_-
  # Operators(sql_functions), Predicates, Clauses(select, from...), Expressions(columns, tables), Params...
  # they are mixed... everything can contain everything and they must communicate with each other.
  # And how it can be splitted?
  class Builder
    # https://6ftdan.com/allyourdev/2015/05/02/private-module-methods-in-ruby/
    # TODO: all methods private except get_sql, get_partial_sql ?

    def initialize
      @params = []
    end

    # get complete sql structure for constructor.
    def get_sql(structure, options)
      # get_partial_sql structure, key: 'sql'
      wrap_result send("build_#{options[:key] || 'sql'}", structure)
    end

    # def get_partial_sql(structure, options)
    # wrap_result send("build_#{options[:key]}", structure)
    # end

    private

    # TODO: update, delete, insert, group.....
    def build_sql(structure)
      structure = structure.is_a?(Constructor) ? structure.structure : structure
      sql = ''
      [:with, :union, :select, :insert, :update, :delete, :set, :from,
       :join, :where, :returning, :group, :order, :limit, :offset].each do |i|
         next unless structure[i]
         sql += send("build_#{i}", structure[i], structure)
       end
      sql
    end

    def method_missing(name, *args)
      /(?<type>[^_]+)_(?<action>\w+)/ =~ name
      # arguments = [action]
      if type && respond_to?("#{type}_missing", true)
        send "#{type}_missing", action, *args
      else
        super
      end
    end

    # TODO
    # def construct_as(field, name)
    # end

    # all functions and column aliases begins from _
    def check_alias(val)
      val.to_s =~ /^_/
    end

    def clear_alias(val)
      val.to_s.sub(/^_/, '')
    end

    def iterate_hash(data, join = true)
      iterations = data.map { |k, v| yield(k, v) }
      join ? iterations.join(', ') : iterations
    end

    def map_and_join(data, joiner = ', ', &block)
      data.map(&block).join(joiner)
    end
  end
end
