# frozen_string_literal: true

module Terrazine
  module Compilers
    module AdvancedOperators
      class Values < Compilers::Base
        # TODO: it is clause?? Should i support Order, limit....?
        def build(structure)
          content = call_multimethod(structure)
          if @wrap
            "VALUES #{value_pattern(content)}"
          else
            "VALUES #{content}"
          end
        end

        private

        def after_initialize_callback
          @wrap = true
        end

        def value_pattern(value)
          "(#{value})"
        end

        # [something]
        # => (parsed)
        # [[something], [something_2]]
        # => (parsed_something), (parsed_something_2)
        assign_multimethod(Array) do |structure|
          map_and_join(structure) do |i|
            if i.is_a?(Array)
              @wrap = false
              value_pattern(call_multimethod(i))
            else
              call_multimethod(i)
            end
          end
        end

        # {columns: [], as: :t, values: [values]}
        # => "(parsed_values) AS t (parsed_columns)"
        assign_multimethod(Hash) do |structure|
          content = "#{call_multimethod(structure[:values])} " \
                    "AS #{structure[:as]} " +
                    value_pattern(expressions(structure[:columns]))
          @wrap = false
          content
        end

        # "Aeonax" => "'Aeonax'"
        # "_something" => "something"
        assign_multimethod(String) do |structure|
          if alias?(structure)
            @wrap = false
            value_pattern(clear_alias(structure))
          else
            to_sql(structure)
          end
        end

        # Take a look on `to_sql` method
        assign_default do |structure|
          to_sql(structure)
        end
      end
    end
  end
end
