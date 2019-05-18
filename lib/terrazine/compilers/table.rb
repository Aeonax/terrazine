# frozen_string_literal: true

module Terrazine
  module Compilers
    class Table < Base
      # :table
      # => table
      #
      # [:table, :t]
      # => table AS t
      # [:table, :t, [:column_1, :column_2]]
      # => table AS t (column_1, column_2)
      # [{:select || :values || :union}, :t, [:column_1]]
      # => (SELECT || VALUES || UNION) AS t (column_1)
      # [[:table, :t], {:values, :something}]
      # => table AS t, (VALUES (something))
      # [:_some_operator, :arg_1, :arg_2]
      # => SOME_OPERATOR(arg_1, arg_2)
      #
      # {select: :true}
      # => (SELECT * )
      def compile(structure = initial_structure)
        multimethod(structure)
      end

      def_multi(Array) do |structure|
        if alias?(structure.first)
          "(#{operators(structure)})"
        elsif [String, Symbol].include?(structure.second.class)
          res = "#{multimethod(structure.first)} AS #{structure.second}"
          next res unless structure[2]
          res + " (#{expressions(structure[2])})"
        else
          map_and_join(structure) { |i| multimethod i }
        end
      end

      def_multi(Hash) do |structure|
        "(#{clauses(structure)})"
      end

      def_multi(CONSTRUCTOR_CLASS) do |structure|
        multimethod(structure.structure)
      end

      def_multi([String, Symbol], &:to_s)

      def_default_multi do |structure|
        raise "Undefined structure for FROM - #{structure}"
      end
    end
  end
end
