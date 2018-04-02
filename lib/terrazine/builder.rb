module Terrazine
  # build structures in to sql string
  class Builder
    attr_accessor :sql, :constructor

    def initialize(constructor)
      @constructor = constructor
      @params = []
    end

    # TODO: update, delete, insert.....
    def build_sql(structure)
      structure = structure.is_a?(Constructor) ? structure.structure : structure
      sql = ''
      sql += "WITH #{build_with(structure[:with])} " if structure[:with]
      # puts "build_sql, structure: #{structure}"
      [:union, :select, :insert, :update, :delete, :set, :from, :join, :where,
       :group, :order, :limit, :offset].each do |i|
         next unless structure[i]
         sql += send("build_#{i}".to_sym, structure[i])
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

    def build_with(structure)
      if structure.second.is_a? Hash
        "#{structure.first} AS (#{build_sql(structure.last)})"
      else
        structure.map { |v| build_with(v) }.join ', '
      end
    end

    # def build_select_query(structure)
    # puts "build_select_query, structure: #{structure}"
    # sql += build_select(structure[:select], structure[:distinct]) if structure[:select]
    # [:from, :join, :where, :order, :limit, :offset].each do |i|
    # sql += send("build_#{i}", structure[i]) if structure[i]
    # end
    # end

    def build_union(structure)
      structure.map { |i| build_sql(i) }.join ' UNION '
    end

    def build_distinct_select(distinct)
      case distinct
      when Array
        "DISTINCT ON(#{build_columns fields}) "
      when true
        'DISTINCT '
      end
    end

    def build_select(structure, distinct = nil)
      # puts "build_select, structure #{structure}"
      "SELECT #{build_distinct_select distinct}#{build_columns structure} "
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

    def build_from(structure)
      "FROM #{build_tables(structure)} "
    end

    def conditions_constructor(structure, joiner = :and, level = nil)
      case structure
      when Array
        key = structure.first
        # AND, OR support
        if key.is_a? Symbol
          res = structure.drop(1).map { |i| conditions_constructor(i) }.join " #{key} ".upcase
          level ? res : "(#{res})"
        # Sub Queries support - ['rgl IN ?', {...}]
        elsif key =~ /\?/
          if [Hash, Constructor].include?(structure.second.class)
            key.sub(/\?/, "(#{build_sql(structure.second)})")
          else
            key.sub(/\?/, build_param(structure.second))
          end
        else
          res = structure.map { |i| conditions_constructor(i) }.join " #{joiner} ".upcase
          level ? res : "(#{res})"
        end
      when String
        structure
      end
    end

    # TODO? conditions like [:eq :name :Aeonax]
    def build_conditions(structure)
      conditions_constructor(structure, :and, true) + ' '
    end

    # TODO: -_-
    def build_join(structure)
      if structure.is_a? Array
        # TODO: hash is sux here -_- !!!!!!
        if structure.second.is_a? Hash
          name = build_tables structure.first # (name.is_a?(Array) ? name.join(' ') : name)
          v = structure.second
          "#{v[:option].to_s.upcase + ' ' if v[:option]}JOIN #{name} ON #{build_conditions v[:on]}"
        else
          structure.map { |i| build_join(i) }.join
        end
      else
        structure =~ /join/i ? structure : "JOIN #{structure} "
      end
    end

    def build_where(structure)
      "WHERE #{build_conditions(structure)} "
    end

    # TODO!
    def build_order(structure)
      "ORDER BY #{structure} "
    end

    def build_limit(limit)
      "LIMIT #{limit || 8} "
    end

    def build_offset(offset)
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
              build_as(build_columns(v, prefix), k)
            else
              build_columns(v, k.to_s)
            end
          end
        end
      when Symbol, String
        structure = structure.to_s
        if prefix && structure !~ /, |\./
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

    # TODO!!!!!!! Relocate in class FunctionsBuilder? and send function name in it.
    def build_function(structure, prefix = nil)
      function = structure.first.to_s.sub(/^_/, '')
      arguments = structure.drop(1)
      case function.to_sym
      when :param
        build_param arguments.first
      when :count # TODO? alias support on this lvl
        if arguments.count > 1
          arguments.map { |i| "COUNT(#{build_columns(i, prefix)})" }.join ','
        else
          "COUNT(#{build_columns(arguments.first, prefix)})"
        end
      when :nullif
        # TODO? querry for value
        "NULLIF(#{build_columns(arguments.first, prefix)}, #{arguments[1]})"
      when :array # TODO? build_columns support
        if [Hash, Constructor].include?(arguments.first.class)
          "ARRAY(#{build_sql arguments.first})"
        else # TODO? condition and error case
          "ARRAY[#{arguments.join ', '}]"
        end
      when :avg
        "AVG(#{build_columns(arguments.first, prefix)})"
      when :values
        "(VALUES(#{build_columns arguments.first, prefix})) AS #{structure[2]} (#{build_columns arguments.last})"
      when :case
        else_val = "ELSE #{arguments.pop} " unless arguments.last.is_a? Array
        conditions = arguments.map { |i| "WHEN #{i.first} THEN #{i.last}" }.join ' '
        "CASE #{conditions} #{else_val}END"
      when :coalesce
        "COALESCE(#{build_columns(arguments, prefix)})"
      else
        raise "Unknown function #{function}" # TODO: errors-_-
      end
    end
  end
end
