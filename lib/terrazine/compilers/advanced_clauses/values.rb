# frozen_string_literal: true

module Terrazine
  module Compilers
    module AdvancedClauses
      class Values < Compilers::Base
        def after_initialize_callback
          @wrap = true
        end

        def build(structure)
          content = multimethod(structure)
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
        def_multi(Array) do |structure|
          # hell....
          if structure.count == 1 && structure.first.is_a?(Array)
            next multimethod(structure.first)
          end

          next expressions(structure) if alias?(structure.first)

          if structure.all? { |i| i.is_a?(Array) && !alias?(i.first) }
            @wrap = false
            next map_and_join(structure) { |i| value_pattern(multimethod(i)) }
          end

          map_and_join(structure) { |i| multimethod(i) }
        end

        def_multi(String) do |structure|
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

        def_default_multi do |structure|
          expressions(structure)
        end
      end
    end
  end
end
