# frozen_string_literal: true

module Terrazine
  module Compilers
    class Operator < Base
      def_multi(:and) do |*structure|
        map_and_join(structure, ' AND ') { |i| conditions(i) }
      end

      def_multi(:or) do |*structure|
        map_and_join(structure, ' OR ') { |i| conditions(i) }
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

      def_multi(:eq) do |column, value|
        eq(value, column)
      end

      def_multi(:eq, Array) do |value, column|
        multimethod_by(:in, column, value)
      end

      def_multi(:eq, [TrueClass, FalseClass, NilClass]) do |value, column|
        multimethod_by(:is, column, value)
      end

      def_default_multi(:eq) do |value, column|
        "#{expressions column} = #{expressions value}"
      end

      def_multi(:is) do |expr, value|
        "#{expressions expr} IS #{to_sql value}"
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

      def_multi(:like) do |*structure|
        comparison_format('LIKE', structure)
      end

      def_multi(:ilike) do |*structure|
        comparison_format('iLIKE', structure)
      end

      def_multi(:reg) do |*structure|
        comparison_format('~', structure)
      end

      def_multi(:reg_i) do |*structure|
        comparison_format('~*', structure)
      end

      def_multi(:reg_f) do |*structure|
        comparison_format('!~', structure)
      end

      def_multi(:reg_fi) do |*structure|
        comparison_format('!~*', structure)
      end

      # https://www.postgresql.org/docs/10/functions-comparison.html
      def_multi(:between) do |value, lesser, bigger|
        "#{expressions value} BETWEEN #{multimethod_by(:and, lesser, bigger)}"
      end

      def_multi(:more) do |*structure|
        comparison_format('>', structure)
      end

      def_multi(:less) do |*structure|
        comparison_format('<', structure)
      end

      def_multi(:more_eq) do |*structure|
        comparison_format('>=', structure)
      end

      def_multi(:less_eq) do |*structure|
        comparison_format('<=', structure)
      end

      # def_multi(:not_eq) do |*structure|
      # comparison_format('!=', structure)
      # end

      private

      def comparison_format(pattern, structure)
        "#{expressions structure.first} #{pattern} " \
        "#{expressions structure.second}"
      end
    end
  end
end
