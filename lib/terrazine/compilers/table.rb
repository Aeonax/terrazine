# frozen_string_literal: true

module Terrazine
  module Compilers
    class Table < Base
      def compile(structure = initial_structure)
        call_multimethod(structure)
      end

      assign_multimethod(Array) do |structure|
        next "(#{operators(structure)})" if alias?(structure.first)
        map_and_join(structure, ' AS ') { |i| call_multimethod i }
      end

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
