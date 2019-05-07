module Terrazine
  module Compilers
    module AdvancedCompilers
      class With < Compilers::Base
        def build(structure)
          "WITH #{call_multimethod(structure)} "
          # case structure
          # when Array
          #   if structure.second.is_a? Hash
          #     "#{structure.first} AS (#{clauses(structure.last)})"
          #   else
          #     structure.map { |v| build(v) }.join ', '
          #   end
          # when Hash
          #   map_and_join(structure) { |k, v| "#{k} AS (#{clauses(v)})" }
          # else
          #   raise
          # end
        end

        def single_entity(name, structure)
          "#{name} AS (#{clauses(structure)})"
        end

        assign_multimethod(Array) do |structure|
          if structure.second.is_a? Hash
            single_entity(structure.first, structure.last)
          elsif structure.second.is_a?(Constructor)
            single_entity(structure.first, structure.last.structure)
          else
            map_and_join(structure) { |v| call_multimethod(v) }
          end
        end

        assign_multimethod(Hash) do |structure|
          map_and_join(structure) { |k, v| single_entity(k, v) }
        end

        # assign_multimethod(Constructor) do |structure|
        # call_multimethod(structure.structure)
        # end

        assign_default do |structure|
          raise "Undefined value for WITH clause: #{structure}"
        end
      end
    end
  end
end
