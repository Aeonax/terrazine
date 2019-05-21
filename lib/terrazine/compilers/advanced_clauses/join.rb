# frozen_string_literal: true

module Terrazine
  module Compilers
    module AdvancedClauses
      class Join < Compilers::Base
        def build(structure)
          multimethod(structure)
        end

        private

        def result
          "#{@type.to_s.upcase + ' ' if @type}JOIN #{@table} ON #{@on} "
        end

        # [{users: {on: ...}}, {...}]
        # => JOIN users ON ... JOIN ...
        def_multi(Array) do |structure|
          map_and_join(structure, '') { |i| multimethod(i) }
        end

        # { any_table_syntax => condition || {on: condition, type: :left}}
        # LEFT JOIN some_table s_t ON condition
        def_multi(Hash) do |structure|
          map_and_join(structure) do |k, v|
            parse_value(v)
            @table = tables(k)
            result
          end
        end

        # pass as it is
        def_multi(String) do |structure|
          structure
        end

        def_default_multi do |structure|
          raise "Undefined structure: #{structure} for JOIN!"
        end

        def_multi(:parse_value, Hash) do |structure|
          if structure[:on]
            @type = structure[:type]
            @on = conditions(structure[:on])
          else
            @on = conditions(structure)
          end
        end

        def_default_multi(:parse_value) do |structure|
          @on = conditions(structure)
        end
      end
    end
  end
end
