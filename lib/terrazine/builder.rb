require_relative 'builders/functions'
require_relative 'builders/conditions'

module Terrazine
  # builds structures in to sql string
  # TODO: SPLIT!!! But how-_-
  # Operators(sql_functions), Predicates, Clauses(select, from...), Expressions(columns, tables)...
  # they are mixed... everything can contain everything and they must communicate with each other.
  # And how it can be splitted?
  class Builder
    attr_accessor :sql, :constructor

    # https://6ftdan.com/allyourdev/2015/05/02/private-module-methods-in-ruby/
    # TODO: all methods private except get_sql, get_partial_sql ?

    def initialize
      @params = []
    end

    # get complete sql structure for constructor.
    def get_sql(structure)
      get_partial_sql structure, key: 'sql'
      # wrap_result build_sql(structure)
    end

    def get_partial_sql(structure, options)
      wrap_result send("build_#{options[:key]}", structure)
    end

    private

    def wrap_result(sql)
      res = @params.count.positive? ? [sql, @params] : sql
      @params = []
      res
    end

    # TODO: update, delete, insert, group.....
    def build_sql(structure)
      structure = structure.is_a?(Constructor) ? structure.structure : structure
      sql = ''
      [:with, :union, :select, :insert, :update, :delete, :set, :from,
       :join, :where, :group, :order, :limit, :offset].each do |i|
         next unless structure[i]
         sql += send("build_#{i}", structure[i], structure)
       end
      sql
    end

    def build_with(structure, _)
      "WITH #{construct_with(structure)} "
    end

    def build_union(structure, _)
      structure.map { |i| build_sql(i) }.join ' UNION '
    end

    def build_select(structure, common_structure)
      distinct = construct_distinct common_structure[:distinct]
      "SELECT #{distinct}#{build_columns structure} "
    end

    def build_from(structure, _)
      "FROM #{build_tables(structure)} "
    end

    # TODO: -_-
    def build_join(structure, _)
      if structure.is_a? Array
        # TODO: hash is sux here -_- !!!!!!
        if structure.second.is_a? Hash
          name = build_tables structure.first # (name.is_a?(Array) ? name.join(' ') : name)
          v = structure.second
          "#{v[:option].to_s.upcase + ' ' if v[:option]}JOIN #{name} ON #{build_conditions v[:on]} "
        else
          structure.map { |i| build_join(i, nil) }.join
        end
      else
        structure =~ /join/i ? structure : "JOIN #{structure} "
      end
    end

    def build_where(structure, _)
      "WHERE #{build_conditions(structure)} "
    end

    # TODO!
    def build_order(structure, _)
      "ORDER BY #{construct_order structure} "
    end

    def build_limit(limit, _)
      "LIMIT #{limit || 8} "
    end

    def build_offset(offset, _)
      "OFFSET #{offset || 0} "
    end

    # Common builders...

    def build_function(structure, prefix = nil)
      function = structure.first.to_s.sub(/^_/, '')
      arguments = structure.drop(1)
      send(function, arguments, prefix)
    end

    def build_tables(structure)
      case structure
      when Array
        if check_alias(structure.first) # VALUES function or ...?
          build_function(structure)
        # if it's a array with strings/values
        elsif structure.select { |i| i.is_a? Array }.empty? # array of table_name and alias
          structure.join ' '
        else # array of tables/values
          structure.map { |i| i.is_a?(Array) ? build_tables(i) : i }.join(', ')
        end
      when String, Symbol
        structure
      else
        raise "Undefined structure for FROM - #{structure}"
      end
    end

    # TODO: split
    def build_columns(structure, prefix = nil)
      case structure
      when Array
        # SQL function - in format: "_#{fn}"
        if check_alias(structure.first)
          build_function structure, prefix
        else
          structure.map { |i| build_columns i, prefix }.join ', '
        end
      when Hash
        # sub_query
        if structure[:select]
          "(#{build_sql(structure)})"
        # colum OR table alias
        else
          iterate_hash(structure) do |k, v|
            if check_alias(k)
              construct_as(build_columns(v, prefix), k)
            else
              build_columns(v, k.to_s)
            end
          end
        end
      when Symbol, String, Integer
        structure = structure.to_s
        if prefix && structure !~ /, |\.|\(/
          "#{prefix}.#{structure}"
        else
          structure
        end
      when Constructor
        "(#{build_sql structure.structure})"
      when true # choose everything -_-
        build_columns('*', prefix)
      else # TODO: values from value passing here... -_-
        structure
        # raise "Undefined class: #{structure.class} of #{structure}" # TODO: ERRORS class
      end
    end

    # Builder Constructors

    # hmmmmm... -_-
    def construct_as(field, name)
      "#{field} AS #{name.to_s.sub(/^_/, '')}" # update ruby for delete_prefix? =)
    end

    # TODO: :with_recursive
    def construct_with(structure)
      case structure
      when Array
        if structure.second.is_a? Hash
          "#{structure.first} AS (#{build_sql(structure.last)})"
        else
          structure.map { |v| construct_with(v) }.join ', '
        end
      when Hash
        iterate_hash(structure) { |k, v| "#{k} AS (#{build_sql v})" }
      else
        raise
      end
    end

    def construct_distinct(structure)
      return unless structure
      if structure == true
        'DISTINCT '
      else
        "DISTINCT ON(#{build_columns structure}) "
      end
    end

    # { name: :asc, email: [:desc, :last] }
    # [:name, :email, { phone: :last }]
    def construct_order(structure)
      case structure
      when Array # function or values for order
        if check_alias structure.first
          build_function structure
        else
          structure.map { |i| construct_order i }.join ', '
        end
      when Hash
        iterate_hash(structure) { |k, v| "#{construct_order k} #{construct_order_options v}" }
      else
        structure
      end
    end

    def construct_order_options(option)
      case option
      when Array
        option.sort.map { |i| construct_order_options i }.join ' '
      when :last, :first
        "nulls #{option}".upcase
      when :asc, :desc
        option.to_s.upcase
      else
        "USING#{option}"
      end
    end

    def build_param(value)
      # no need for injections check - pg gem will check it
      @params << value
      "$#{@params.count}"
    end

    # all functions and column aliases begins from _
    def check_alias(val)
      val.to_s =~ /^_/
    end

    def iterate_hash(data, join = true)
      iterations = []
      data.each { |k, v| iterations << yield(k, v) }
      join ? iterations.join(', ') : iterations
    end
  end
end
