# frozen_string_literal: true

module Terrazine
  module Compilers
    class Expression < Base
      def compile(structure = initial_structure,
                  prefix = @options[:prefix])
        call_multimethod(structure, prefix)
      end

      assign_multimethod(Array) do |structure, prefix|
        if alias?(structure.first)
          operators(structure, prefix)
        else
          map_and_join(structure) { |i| call_multimethod(i, prefix) }
        end
      end

      assign_multimethod(Hash) do |structure, prefix|
        next "(#{clauses(structure)})" if structure[:select]

        map_and_join(structure) do |k, v|
          if alias?(k)
            "#{call_multimethod(v, prefix)} AS #{clear_alias(k)}"
          else
            call_multimethod(v, k.to_s)
          end
        end
      end

      assign_multimethod([String, Symbol]) do |structure, prefix|
        structure = structure.to_s
        if prefix && structure !~ /, |\.|\(/
          "#{prefix}.#{structure}"
        else
          structure
        end
      end

      assign_multimethod(Constructor) do |structure, _prefix|
        "(#{clauses(structure.structure)})"
      end

      assign_multimethod(TrueClass) do |_structure, prefix|
        call_multimethod('*', prefix)
      end

      # TODO: values from value passing here... -_-  # ... wtf?
      assign_default do |structure, _prefix|
        structure
        # raise "Undefined class: #{structure.class} of #{structure}"
      end
    end
  end
end
