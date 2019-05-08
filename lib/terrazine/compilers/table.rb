# frozen_string_literal: true

module Terrazine
  module Compilers
    class Table < Base
      def compile(structure = initial_structure)
        call_multimethod(structure)
      end

      assign_multimethod(Array) do |structure|
        if alias?(structure.first) # VALUES function or ...?
          "(#{operators(structure)})"
        elsif structure.select { |i| i.is_a? Array }.empty?
          map_and_join(structure) { |i| call_multimethod i }
        else
          map_and_join(structure, ' AS ') { |i| call_multimethod i }
        end
      end

      assign_multimethod(Hash) do |structure|
        "(#{clauses(structure)})"
      end

      assign_multimethod(Constructor) do |structure|
        call_multimethod(structure.structure)
      end

      assign_multimethod([String, Symbol]) do |structure|
        structure
      end

      assign_default do |structure|
        raise "Undefined structure for FROM - #{structure}"
      end
    end
  end
end
