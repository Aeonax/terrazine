# frozen_string_literal: true

module Terrazine
  module Compilers
    module AdvancedClauses
      class Values < Compilers::Base
        def after_initialize_callback
          @wrap = true
        end

        def build(structure)
          content = call_multimethod(structure)
          content = value_pattern(content) if @wrap
          "VALUES #{content} "
        end

        private

        def value_pattern(value)
          "(#{value})"
        end

        # [:_count]
        # (COUNT(*))
        # [[:_count], [:_count]]
        # => (COUNT(*)), (COUNT(*))
        # [:name, :email, [:_count]]
        # => (name, email, COUNT(*))
        assign_multimethod(Array) do |structure|
          # hell....
          if structure.count == 1 && structure.first.is_a?(Array)
            next call_multimethod(structure.first)
          end

          next expressions(structure) if alias?(structure.first)

          if structure.all? { |i| i.is_a?(Array) && !alias?(i.first) }
            @wrap = false
            next map_and_join(structure) { |i| value_pattern(call_multimethod(i)) }
          end

          map_and_join(structure) { |i| call_multimethod(i) }
        end

        assign_multimethod(String) do |structure|
          if structure =~ /^!/
            @wrap = false
            structure.to_s.sub(/^!/, '')
          # if alias?(structure)
          # @wrap = false
          # clear_alias(structure)
          else
            to_sql(structure)
          end
        end

        assign_default do |structure|
          expressions(structure)
        end
      end
    end
  end
end
