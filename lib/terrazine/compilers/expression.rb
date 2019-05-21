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
            "#{multimethod(v, prefix)} AS #{clear_prefix(k)}"
          else
            multimethod(v, k.to_s)
          end
        end
      end

      def_multi([String, Symbol]) do |i_structure, prefix|
        structure = i_structure.to_s
        next structure if structure =~ /, |\.|\(/

        if prefix
          "#{prefix}.#{structure}"
        elsif structure =~ /__/
          structure.to_s.sub(/__/, '.')
        else
          i_structure.is_a?(String) ? to_sql(structure) : structure
        end
      end

      def_multi(Constructor) do |structure, _prefix|
        "(#{clauses(structure.structure)})"
      end

      # def_multi(TrueClass) do |_structure, prefix|
      #   # multimethod('*', prefix)
      #   "#{prefix + '.' if prefix}*"
      # end

      # TODO: values from value passing here... -_-  # ... wtf?
      def_default_multi do |structure, _prefix|
        to_sql(structure)
        # raise "Undefined class: #{structure.class} of #{structure}"
      end
    end
  end
end
