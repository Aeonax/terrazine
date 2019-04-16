# frozen_string_literal: true

module Terrazine
  module Compilers
    class Base
      def initialize(options)
        @options = options
        # @structure = options[:structure] ? options.delete(:structure) : {}
        after_initialize
      end

      def initial_structure
        @options[:structure] || {}
      end

      def params
        @options[:params] ||= []
      end

      def initial_or_(structure, name)
        structure.empty? ? initial_structure[name] : structure
      end

      def build_param(param)
        params << param
        "$#{params.count}"
      end

      # where it should be?
      def to_sql(data)
        case data
        when String, Symbol
          data = data.to_s
          if data =~ /true|false/
            data.upcase
          else
            "'#{data}'"
          end
        when TrueClass, FalseClass
          data.to_s.upcase
        when nil
          'NULL'
        else
          data
        end
      end

      private

      def after_initialize; end
    end
  end
end
