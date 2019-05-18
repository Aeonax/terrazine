# frozen_string_literal: true

module Terrazine
  module Compilers
    class Base
      CONSTRUCTOR_CLASS = Constructor

      class << self
        def def_multi(*args, &method)
          distinction = if args.count > 1
                          method_name = args.first
                          args.second
                        else
                          method_name = :multimethod
                          args.first
                        end
          multimethod(method_name).add_method(distinction, &method)
        end

        def def_default_multi(method_name = :multimethod, &method)
          multimethod(method_name).assign_default(&method)
        end

        def multimethod(method_name)
          method = "@#{method_name}"
          return instance_variable_get(method) if instance_variable_defined?(method)

          m = instance_variable_set(method, Multimethods.new)
          define_method(method_name) do |*args|
            instance_exec(*args, &m.fetch_method(args.first))
          end
          m
        end
      end

      def initialize(options)
        @options = options
        # @structure = options[:structure] ? options.delete(:structure) : {}
        after_initialize_callback
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

      def add_param
        # TODO!
      end

      # for array args like `*structure` only!!!
      def initial_or_(structure, name)
        structure.empty? ? initial_structure[name] : structure.first
      end

      def alias?(val)
        return unless [String, Symbol].include?(val.class)
        val.to_s =~ /^_/
      end

      def hash_is_sub_query?(structure)
        structure[:select] || structure[:union] || structure[:values]
      end

      def constructor?(structure)
        structure.is_a?(CONSTRUCTOR_CLASS)
      end

      # update ruby for delete_prefix? =)
      def clear_alias(val)
        val.to_s.sub(/^_/, '')
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

      def compiler_options(options)
        @options.merge(options).except(:structure)
      end
    end
  end
end
