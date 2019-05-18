# frozen_string_literal: true

module Terrazine
  module Compilers
    class Expression < Base
      def compile(structure = initial_structure,
                  prefix = @options[:prefix])
        multimethod(structure, prefix)
      end

      def_multi(Array) do |structure, prefix|
        if alias?(structure.first)
          operators(structure, prefix)
        else
          map_and_join(structure) { |i| multimethod(i, prefix) }
        end
      end

      def_multi(Hash) do |structure, prefix|
        next "(#{clauses(structure)})" if structure[:select]

        map_and_join(structure) do |k, v|
          if alias?(k)
            "#{multimethod(v, prefix)} AS #{clear_alias(k)}"
          else
            multimethod(v, k.to_s)
          end
        end
      end

      def_multi([String, Symbol]) do |structure, prefix|
        structure = structure.to_s
        if prefix && structure !~ /, |\.|\(/
          "#{prefix}.#{structure}"
        else
          structure
        end
      end

      def_multi(Constructor) do |structure, _prefix|
        "(#{clauses(structure.structure)})"
      end

      def_multi(TrueClass) do |_structure, prefix|
        multimethod('*', prefix)
      end

      # TODO: values from value passing here... -_-  # ... wtf?
      def_default_multi do |structure, _prefix|
        structure
        # raise "Undefined class: #{structure.class} of #{structure}"
      end
    end
  end
end
