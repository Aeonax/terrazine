# frozen_string_literal: true

module Terrazine
  module Compilers
    module AdvancedOperators
      class Arrays < Compilers::Base
        def build(structure)
          "ARRAY#{call_multimethod(structure)}"
        end

        private

        def clauses(structure)
          "(#{super(structure)})"
        end

        def expressions(structure)
          "[#{super(structure)}]"
        end

        assign_multimethod(Hash) do |structure|
          if hash_is_sub_query?(structure)
            clauses(structure)
          else
            expressions(structure)
          end
        end

        assign_multimethod(CONSTRUCTOR_CLASS) do |structure|
          clauses(structure.structure)
        end

        # [:name, :email]
        # => [name, email]
        # [[:name, :email], [:mrgl, :rgl]]
        # => [[name, email], [mrgl, rgl]]
        assign_multimethod(Array) do |structure|
          if structure.all? { |i| i.is_a?(Array) && !alias?(i.first) }
            next "[#{map_and_join(structure) { |i| call_multimethod(i) }}]"
          end

          expressions(structure)
        end

        assign_default do |structure|
          expressions(structure)
        end
      end
    end
  end
end
