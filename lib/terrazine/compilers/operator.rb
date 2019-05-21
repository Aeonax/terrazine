# frozen_string_literal: true

require_relative 'advanced_operators/arrays'

module Terrazine
  module Compilers
    class Operator < Base
      def compile(structure = initial_structure)
        operator = clear_prefix(structure.first).to_sym
        arguments = structure.drop(1)

        # send(operator, *arguments)
        multimethod_by(operator, *arguments)
        # TODO: rescue invalid args amount
      end

      initialize_multi(:itself)

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

      # conditional operators

      def_multi(:and) do |*structure|
        map_and_join(structure, ' AND ') { |i| expressions(i) }
      end

      def_multi(:or) do |*structure|
        map_and_join(structure, ' OR ') { |i| expressions(i) }
      end

      # map array as COUNT?
      def_multi(:not) do |*structure|
        value = if structure.count == 1
                  expressions(structure)
                else
                  multimethod_by(:eq, *structure)
                end
        "NOT #{value}"
      end

      def_multi(:in) do |expr, value|
        "#{expressions(expr)} IN #{in_values(value)}"
      end

      def_multi(:in_values, [Hash, Constructor]) do |structure|
        "(#{clauses(structure)})"
      end

      def_multi(:in_values, Array) do |structure|
        "(#{map_and_join(structure) { |i| expressions(i) }})"
      end

      def_default_multi(:in_values) do |structure|
        "(#{structure})"
      end

      def_multi(:eq) do |column, value|
        next multimethod_by(:in, column, value) if value.is_a? Array
        "#{expressions column} = #{expressions value}"
      end

      def_multi(:is) do |expr, value|
        "#{expressions expr} IS #{to_sql value}"
      end

      def_multi(:between) do |*structure|
        value = if structure.count == 1
                  expressions(structure.first)
                else
                  multimethod_by(:and, *structure)
                end
        "BETWEEN #{value}"
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

      def_multi(:like) do |*structure|
        pattern_format('LIKE', structure)
      end

      def_multi(:ilike) do |*structure|
        pattern_format('iLIKE', structure)
      end

      def_multi(:reg) do |*structure|
        pattern_format('~', structure)
      end

      def_multi(:reg_i) do |*structure|
        pattern_format('~*', structure)
      end

      def_multi(:reg_f) do |*structure|
        pattern_format('!~', structure)
      end

      def_multi(:reg_fi) do |*structure|
        pattern_format('!~*', structure)
      end

      # TODO: > < >= <= ...

      private

      def pattern_format(pattern, structure)
        "#{expressions structure.first} #{pattern} " \
        "#{expressions structure.second}"
      end

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
