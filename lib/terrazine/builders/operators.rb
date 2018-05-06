module Terrazine
  class Builder
    private

    # now it doesnt use Predicates

    def build_operator(structure, prefix = nil)
      operator = structure.first.to_s.sub(/^_/, '')
      arguments = structure.drop(1)
      # puts operator
      send("operator_#{operator}", arguments, prefix)
    end

    def operator_missing(name, arguments, prefix)
      "#{name}(#{build_columns arguments, prefix})"
    end

    def operator_params(arguments, _)
      if arguments.count > 1
        arguments.map { |i| build_param i }
      else
        build_param arguments.first
      end
    end

    # without arguments smthng like this - "COUNT(#{prefix + '.'}*)"
    def operator_count(arguments, prefix)
      if arguments.count > 1
        arguments.map { |i| "COUNT(#{build_columns(i, prefix)})" }.join ', '
      else
        "COUNT(#{build_columns(arguments.first, prefix)})"
      end
    end

    def operator_nullif(arguments, prefix)
      "NULLIF(#{build_columns(arguments.first, prefix)}, #{arguments[1]})"
    end

    def operator_array(arguments, prefix)
      if [Hash, Constructor].include?(arguments.first.class)
        "ARRAY(#{build_sql arguments.first})"
      else # TODO? condition and error case
        "ARRAY[#{build_columns arguments, prefix}]"
      end
    end

    def operator_avg(arguments, prefix)
      "AVG(#{build_columns(arguments.first, prefix)})"
    end

    def operator_values(arguments, _)
      values = arguments.first.first.is_a?(Array) ? arguments.first : [arguments.first]
      values.map! { |i| "(#{build_columns i})" }
      "(VALUES#{values.join ', '}) AS #{arguments[1]} (#{build_columns arguments.last})"
    end

    def operator_case(arguments, _)
      else_val = "ELSE #{arguments.pop} " unless arguments.last.is_a? Array
      conditions = arguments.map { |i| "WHEN #{i.first} THEN #{i.last}" }.join ' '
      "CASE #{conditions} #{else_val}END"
    end
  end
end
