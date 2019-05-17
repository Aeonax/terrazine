# frozen_string_literal: true

require_relative 'advanced_operators/arrays'

module Terrazine
  module Compilers
    class Operator < Base
      def compile(structure = initial_structure)
        operator = clear_alias(structure.first)
        arguments = structure.drop(1)
        # puts operator
        send(operator, arguments)
      end

      def params(arguments)
        if arguments.count > 1
          arguments.map { |i| add_param(i) }
        else
          add_param(arguments.first)
        end
      end

      # TODO: meditate over it
      def count(arguments)
        if arguments.is_a?(Array)
          return count(true) if arguments.empty?
          return map_and_join(arguments) { |v| count(v) }
        end

        if arguments.is_a?(Hash)
          return map_and_join(arguments) { |k, v| "#{count(v)} AS #{k}" }
        end

        "COUNT(#{expressions(arguments)})"
      end

      def nullif(arguments)
        "NULLIF(#{expressions(arguments.first)}, " \
        "#{to_sql(arguments[1])})"
      end

      def array(arguments)
        AdvancedOperators::Arrays.new(@options).build(arguments.first)
      end

      def avg(arguments)
        "AVG(#{expressions(arguments.first)})"
      end

      def missing_method_format(method, structure)
        "#{method.upcase}(#{expressions(structure)})"
      end

      private

      def method_missing(operator, *structure)
        if structure.empty?
          operator.upcase
        elsif wrap_in_select?(operator)
          wrap_in_select(operator, *structure)
        else
          missing_method_format(operator, structure)
        end
      end

      def prefix
        @options[:prefix]
      end

      def wrap_in_select?(method)
        [:json_agg, :jsonb_agg, :xmlagg].include?(method)
      end

      def wrap_in_select(operator, structure)
        if structure.first.is_a?(Hash) && hash_is_sub_query?(structure.first)
          expressions(select: missing_method_format(operator, :item),
                      from: [structure, :item])
        else
          missing_method_format(operator, structure)
        end
      end
    end
  end
end
