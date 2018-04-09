module Terrazine
  class Builder
    module Functions
      def params(arguments, _)
        if arguments.count > 1
          arguments.map { |i| build_param i }
        else
          build_param arguments.first
        end
      end

      def count(arguments, prefix)
        if arguments.count > 1
          arguments.map { |i| "COUNT(#{construct_columns(i, prefix)})" }.join ', '
        else
          "COUNT(#{construct_columns(arguments.first, prefix)})"
        end
      end

      def nullif(arguments, prefix)
        "NULLIF(#{construct_columns(arguments.first, prefix)}, #{arguments[1]})"
      end

      def array(arguments, prefix)
        if [Hash, Constructor].include?(arguments.first.class)
          "ARRAY(#{build_sql arguments.first})"
        else # TODO? condition and error case
          "ARRAY[#{construct_columns arguments, prefix}]"
        end
      end

      def avg(arguments, prefix)
        "AVG(#{construct_columns(arguments.first, prefix)})"
      end

      def values(arguments, _)
        values = arguments.first.first.is_a?(Array) ? arguments.first : [arguments.first]
        values.map! { |i| "(#{construct_columns i})" }
        "(VALUES#{values.join ', '}) AS #{arguments[1]} (#{construct_columns arguments.last})"
      end

      def case(arguments, _)
        else_val = "ELSE #{arguments.pop} " unless arguments.last.is_a? Array
        conditions = arguments.map { |i| "WHEN #{i.first} THEN #{i.last}" }.join ' '
        "CASE #{conditions} #{else_val}END"
      end
    end
  end
end
