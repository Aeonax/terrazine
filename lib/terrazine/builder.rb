require_relative 'functions_builder'

module Terrazine
  # build structures in to sql string
  class Builder
    attr_accessor :sql, :constructor
    # do methods inside modules private? https://6ftdan.com/allyourdev/2015/05/02/private-module-methods-in-ruby/
    # rename methods in to "function_#{name}" ?
    include Functions
    # relocate "construct_#{name}" methods in modules and leave here only "build_#{name}"

    def initialize
      @params = []
    end

    # TODO: update, delete, insert.....
    def build_sql(structure)
      structure = structure.is_a?(Constructor) ? structure.structure : structure
      sql = ''
      [:with, :union, :select, :insert, :update, :delete, :set, :from,
       :join, :where, :group, :order, :limit, :offset].each do |i|
         next unless structure[i]
         sql += send("build_#{i}".to_sym, structure[i], structure)
       end
      sql
    end

    # get complete sql structure for constructor.
    def get_sql(structure)
      sql = build_sql structure
      res = @params.count.positive? ? [sql, @params] : sql
      @params = []
      res
    end

    def build_with(structure, _)
      "WITH #{construct_with(structure)} "
    end

    def build_union(structure, _)
      structure.map { |i| build_sql(i) }.join ' UNION '
    end

    def build_select(structure, common_structure)
      distinct = construct_distinct common_structure[:distinct]
      "SELECT #{distinct}#{construct_columns structure} "
    end

    def build_from(structure, _)
      "FROM #{construct_tables(structure)} "
    end

    # TODO: -_-
    def build_join(structure, _)
      if structure.is_a? Array
        # TODO: hash is sux here -_- !!!!!!
        if structure.second.is_a? Hash
          name = construct_tables structure.first # (name.is_a?(Array) ? name.join(' ') : name)
          v = structure.second
          "#{v[:option].to_s.upcase + ' ' if v[:option]}JOIN #{name} ON #{build_conditions v[:on]}"
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

    # { name: :asc, email: [:desc, :last] }
    # [:name, :email, { phone: :last }]
    def construct_order(structure)
      case structure
      when Array # function or values for order
        if check_alias structure.first
          construct_columns structure
        else
          structure.map { |i| construct_order i }.join ', '
        end
      when Hash
        iterate_hash(structure) { |k, v| "#{construct_order k} #{construct_order_options v}" }
      else
        structure
      end
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

    private

    def build_param(value)
      # no need for injections check - pg gem will check it
      @params << value
      "$#{@params.count}"
    end

    # all functions and column aliases begins from _
    def check_alias(val)
      val.to_s =~ /^_/
    end

    def iterate_hash(data)
      iterations = []
      data.each { |k, v| iterations << yield(k, v) }
      iterations.join ', '
    end

    def build_as(field, name)
      "#{field} AS #{name.to_s.sub(/^_/, '')}" # update ruby for delete_prefix? =)
    end

    # TODO? conditions like [:eq :name :Aeonax]
    def build_conditions(structure)
      construct_condition(structure, :and, true) + ' '
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
        "DISTINCT ON(#{construct_columns structure}) "
      end
    end

    def construct_condition(structure, joiner = :and, level = nil)
      case structure
      when Array
        key = structure.first
        # AND, OR support
        if key.is_a? Symbol
          res = structure.drop(1).map { |i| construct_condition(i) }.join " #{key} ".upcase
          level ? res : "(#{res})"
        elsif key =~ /\?/
          # Sub Queries support - ['rgl IN ?', {...}]
          if [Hash, Constructor].include?(structure.second.class)
            key.sub(/\?/, "(#{build_sql(structure.second)})")
          else
            key.sub(/\?/, build_param(structure.second))
          end
        else
          res = structure.map { |i| construct_condition(i) }.join " #{joiner} ".upcase
          level ? res : "(#{res})"
        end
      when String
        structure
      end
    end

    def construct_tables(structure)
      case structure
      when Array
        if check_alias(structure.first) # VALUES function or ...?
          build_function(structure)
        # if it's a array with strings/values
        elsif structure.select { |i| i.is_a? Array }.empty? # array of table_name and alias
          structure.join ' '
        else # array of tables/values
          structure.map { |i| i.is_a?(Array) ? construct_tables(i) : i }.join(', ')
        end
      when String, Symbol
        structure
      else
        raise "Undefined structure for FROM - #{structure}"
      end
    end

    def construct_columns(structure, prefix = nil)
      case structure
      when Array
        # SQL function - in format: "_#{fn}"
        if check_alias(structure.first)
          build_function structure, prefix
        else
          structure.map { |i| construct_columns i, prefix }.join ', '
        end
      when Hash
        # sub_query
        if structure[:select]
          "(#{build_sql(structure)})"
        # colum OR table alias
        else
          iterate_hash(structure) do |k, v|
            if check_alias(k)
              build_as(construct_columns(v, prefix), k)
            else
              construct_columns(v, k.to_s)
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
        construct_columns('*', prefix)
      else # TODO: values from value passing here... -_-
        structure
        # raise "Undefined class: #{structure.class} of #{structure}" # TODO: ERRORS class
      end
    end
  end
end
