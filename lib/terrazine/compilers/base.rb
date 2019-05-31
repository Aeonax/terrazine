# frozen_string_literal: true

module Terrazine
  module Compilers
    class Base
      CONSTRUCTOR_CLASS = Constructor
      extend MultimethodsInterface

      def initialize(options)
        @options = options
        # @structure = options[:structure] ? options.delete(:structure) : {}
        after_initialize_callback
      end

      # TODO!
      def add_param(param)
        params << param
        "$#{params.count}"
      end

      def_multi(:to_sql, [String, Symbol]) do |data|
        data = data.to_s
        if data =~ /true|false/
          data.upcase
        elsif data =~ /^!/ # pass data as it is
          data.sub(/^!/, '')
        else # TODO: replace with params
          # build_param(data)
          "'#{data}'"
        end
      end

      def_multi(:to_sql, [TrueClass, FalseClass]) do |data|
        data.to_s.upcase
      end

      def_multi(:to_sql, nil) do |_data|
        'NULL'
      end

      def_default_multi(:to_sql) do |data|
        data
      end

      private

      def after_initialize_callback; end

      def initial_structure
        @options[:structure] || {}
      end

      def assign_initial_structure(structure)
        @options[:structure] ||= structure
      end

      def params
        @options[:params] ||= []
      end

      # def add_param
      # TODO!
      # end

      # for array args like `*structure` only!!!
      def initial_or_(structure, name)
        structure.empty? ? initial_structure[name] : structure.first
      end

      def prefix?(val, prefix)
        val.to_s =~ prefix
      end

      def alias?(val)
        return unless [String, Symbol].include?(val.class)
        prefix?(val, /^_/)
      end

      def hash_is_sub_query?(structure)
        structure[:select] || structure[:union] || structure[:values]
      end

      def constructor?(structure)
        structure.is_a?(CONSTRUCTOR_CLASS)
      end

      def text?(structure)
        [String, Symbol].include?(structure.class)
      end

      def clear_prefix(val, prefix = /^_/)
        val.to_s.sub(prefix, '')
      end

      def map_and_join(data, joiner = ', ', &block)
        data.map(&block).join(joiner)
      end

      def expressions(data)
        Compiler.compile_expressions(data, @options.except(:structure))
      end

      def clauses(data)
        Compiler.compile_clauses(data, @options.except(:structure))
      end

      def operators(data, prefix = @options[:prefix])
        Compiler.compile_operators(data, compiler_options(prefix: prefix))
      end

      def tables(data)
        Compiler.compile_tables(data, @options.except(:structure))
      end

      def conditions(data)
        Compiler.compile_conditions(data, @options.except(:structure))
      end

      def compiler_options(options)
        @options.merge(options).except(:structure)
      end
    end
  end
end
