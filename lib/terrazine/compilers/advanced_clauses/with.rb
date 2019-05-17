# frozen_string_literal: true

module Terrazine
  module Compilers
    module AdvancedClauses
      class With < Compilers::Base
        def build(structure)
          "WITH #{call_multimethod(structure)} "
        end

        def single_entity(name, structure)
          "#{name} AS (#{clauses(structure)})"
        end

        assign_multimethod(Array) do |structure|
          if structure.second.is_a? Hash
            single_entity(structure.first, structure.last)
          elsif constructor?(structure.second)
            single_entity(structure.first, structure.second)
          else
            map_and_join(structure) { |v| call_multimethod(v) }
          end
        end

        assign_multimethod(Hash) do |structure|
          map_and_join(structure) { |k, v| single_entity(k, v) }
        end

        assign_default do |structure|
          raise "Undefined value for WITH clause: #{structure}"
        end
      end
    end
  end
end
