# frozen_string_literal: true

module Terrazine
  module Compilers
    class Condition < Base
      def compile(structure = initial_structure)
        multimethod(structure)
      end

      # [:_and, [:_eq, :role, 'manager'], [[:_or, 1, false]]]
      # => "role = 'manager' AND (1 OR FALSE)" # .... lol....
      def_multi(Array) do |structure|
        if alias?(structure.first)
          operators(structure)
        else
          "(#{multimethod(structure.first)})"
        end
      end

      def_multi(Hash) do |structure|
        if hash_is_sub_query?(structure)
          "(#{clauses(structure)})"
        else
          result = structure.map { |k, v| operators([:eq, k, v]) }
          operators([:and, *result])
        end
      end

      def_multi(CONSTRUCTOR_CLASS) do |structure|
        multimethod(structure.structure)
      end

      def_default_multi do |structure|
        expressions(structure)
        # raise "Unknown structure for Conditions: #{structure}"
      end
    end
  end
end
