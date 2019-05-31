# frozen_string_literal: true

require_relative 'advanced_operators/arrays'

module Terrazine
  module Compilers
    class Operator < Base
      def compile(structure = initial_structure)
        operator = clear_prefix(structure.first).to_sym
        arguments = structure.drop(1)

        multimethod_by(operator, *arguments)
        # TODO: rescue invalid args amount?
      end

      initialize_multi(differ: :itself, differ_by: true)

      # god damn.... It looks like shit...
      require_relative 'advanced_operators/conditional'

      def_multi(:params) do |structure|
        if structure.is_a?(Array)
          map_and_join(structure) { |i| add_param(i) }
        else
          add_param(structure)
        end
      end

      def_multi(:count) do |structure = nil|
        count(structure)
      end

      def_multi(:count, Array) do |structure|
        map_and_join(structure) { |v| count(v) }
      end

      def_multi(:count, Hash) do |structure|
        map_and_join(structure) { |k, v| "#{count(v)} AS #{k}" }
      end

      def_multi(:count, NilClass) do |_|
        count(:*)
      end

      def_default_multi(:count) do |structure|
        "COUNT(#{expressions(structure)})"
      end

      def_multi(:nullif) do |expr, value|
        "NULLIF(#{expressions(expr)}, " \
        "#{to_sql(value)})"
      end

      def_multi(:array) do |structure|
        AdvancedOperators::Arrays.new(@options).build(structure)
      end

      def_multi(:avg) do |structure|
        "AVG(#{expressions(structure)})"
      end

      def_default_multi do |operator, *structure|
        if structure.empty?
          operator.upcase
        elsif wrap_in_select?(operator)
          wrap_in_select(operator, *structure)
        else
          method_missing_format(operator, *structure)
        end
      end

      private

      def method_missing_format(method, structure)
        "#{method.upcase}(#{expressions(structure)})"
      end

      def prefix
        @options[:prefix]
      end

      def wrap_in_select?(method)
        [:json_agg, :jsonb_agg, :xmlagg].include?(method)
      end

      def wrap_in_select(operator, structure)
        if structure.is_a?(Hash) && hash_is_sub_query?(structure)
          expressions(select: method_missing_format(operator, :item),
                      from: [structure, :item])
        elsif structure.is_a?(CONSTRUCTOR_CLASS)
          wrap_in_select(operator, structure.structure)
        else
          method_missing_format(operator, structure)
        end
      end
    end
  end
end
