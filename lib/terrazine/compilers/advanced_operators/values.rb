# frozen_string_literal: true

module Terrazine
  module Compilers
    module AdvancedOperators
      class Values < Compilers::Base
        # TODO: it is clause?? Should i support Order, limit....?
        def build(structure)
          "VALUES #{call_multimethod(structure)}"
        end

        # {columns: [], as: :t, values: [values]}
        # [values] || [[], []] || 1 || true || ...
        assign_multimethod(Array) do |structure|
          if [Array, Hash, String].include?(structure.first.class)
            map_and_join(structure) { |i| call_multimethod(i) }
          else
            "(#{map_and_join(structure) { |i| to_sql(i) }})"
          end
        end

        assign_multimethod(Hash) do |structure|
          "#{call_multimethod(structure[:values])} " \
          "AS #{structure[:as]} " \
          "(#{expressions(structure[:columns])})"
        end

        assign_multimethod(String) do |structure|
          structure
        end

        assign_default do |structure|
          "(#{to_sql(structure)})"
        end
      end
    end
  end
end
