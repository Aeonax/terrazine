# frozen_string_literal: true

module Terrazine
  module Compilers
    class Condition < Base
      def compile(structure = initial_structure)
        multimethod(structure)
      end

      # private

      # What the problem?
      #### - they are begin without _
      # - they shade default functions like and / or
      # some logic is the same, but different structures...
      # string passed as it is or as params or as ?
      # array... should i bother with array params???

      # What is the difference with expressions?
      # - Hash is sugar for eq
      # - array without first symbol is shugar for and
      # operators begins without _

      # def operators(structure, first_level = nil)
      # return expressions(structure) unless structure.is_a?(Array)
      # key = structure.first
      # return super(structure) if first_level || ![:or, :and].include?(key)

      # "(#{super(structure)})"
      # end

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
          # damn... What to do with same keys?
          result = structure.map { |k, v| operators([:eq, k, v]) }
          operators([:and, *result])
        end
      end

      def_multi(CONSTRUCTOR_CLASS) do |structure|
        multimethod(structure.structure)
      end

      def_multi(String) do |structure|
        structure
      end

      def_default_multi do |structure|
        raise "Unknown structure for Conditions: #{structure}"
      end
    end
  end
end
