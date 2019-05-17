# frozen_string_literal: true

module Terrazine
  module Compilers
    class Table < Base
      # :table
      # => table
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
      def compile(structure = initial_structure)
        call_multimethod(structure)
      end

      assign_multimethod(Array) do |structure|
        if alias?(structure.first)
          "(#{operators(structure)})"
        elsif [String, Symbol].include?(structure.second.class)
          res = "#{call_multimethod(structure.first)} AS #{structure.second}"
          next res unless structure[2]
          res + " #{expressions(structure[2])}"
        else
          map_and_join(structure) { |i| call_multimethod i }
        end
      end

      # assign_multimethod(Array) do |structure|
      #   next "(#{operators(structure)})" if alias?(structure.first)
      #   map_and_join(structure, ' AS ') { |i| call_multimethod i }
      # end

      assign_multimethod(Hash) do |structure|
        "(#{clauses(structure)})"
      end

      assign_multimethod(Constructor) do |structure|
        call_multimethod(structure.structure)
      end

      assign_multimethod([String, Symbol], &:to_s)

      assign_default do |structure|
        raise "Undefined structure for FROM - #{structure}"
      end
    end
  end
end
