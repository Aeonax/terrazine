# frozen_string_literal: true

module Terrazine
  module Compilers
    module AdvancedOperators
      class Arrays < Compilers::Base
        def build(structure)
          "ARRAY#{multimethod(structure)}"
        end

        private

        def clauses(structure)
          "(#{super(structure)})"
        end

        def expressions(structure)
          "[#{super(structure)}]"
        end

        def_multi(Hash) do |structure|
          if hash_is_sub_query?(structure)
            clauses(structure)
          else
            expressions(structure)
          end
        end

        def_multi(CONSTRUCTOR_CLASS) do |structure|
          clauses(structure.structure)
        end

        # [:name, :email]
        # => [name, email]
        # [[:name, :email], [:mrgl, :rgl]]
        # => [[name, email], [mrgl, rgl]]
        def_multi(Array) do |structure|
          if structure.all? { |i| i.is_a?(Array) && !alias?(i.first) }
            next "[#{map_and_join(structure) { |i| multimethod(i) }}]"
          end

          expressions(structure)
        end

        def_default_multi do |structure|
          expressions(structure)
        end
      end
    end
  end
end
