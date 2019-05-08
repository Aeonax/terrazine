# frozen_string_literal: true

require_relative 'compiler_params'
require_relative 'compilers/base'
require_relative 'compilers/clause'
require_relative 'compilers/expression'
require_relative 'compilers/operator'

module Terrazine
  # Public interface for interaction with Compilers
  # should handle:
  # - single entity compilation, like `.._clause(:where, [])`
  # - full entity compilation, like `.._clauses(with: .., select: ..)`
  # - should be available for inner and outer use... How it could be done with beauty...-_-
  module Compiler
    # { select: ..., from: ... }
    def compile_sql(structure, options = {})
      Compilers::Clause.new(compiler_options(options, structure)).compile
    end
    alias compile_clauses compile_sql

    # :select, { u: [:name, :email] }
    def compile_clause(name, *values)
      Compilers::Clause.new(compiler_params).send(name, values)
    end

    # Compile single condition
    # `compile_condition(:eq, :u__name, 'Aeonax') #=> "u.name = 'Aeonax'"`
    # with sub query example would be more reliable...
    def compile_condition(name, *values)
      Compilers::Condition.new(compiler_params).send(name, values)
    end

    # Compile conditions structure
    def compile_conditions(structure, options = {})
      Compilers::Condition.new(compiler_options(options, structure)).compile
    end

    # (:sum, :amount, :cost)
    def compile_operator(name, *values)
      Compilers::Operator.new(compiler_params).send(name, values)
    end

    def compile_operator_with_prefix(name, prefix, *values)
      Compilers::Operator.new(compiler_options({ prefix: prefix }, structure))
                         .send(name, values)
    end

    def compile_operators(structure, options = {})
      Compilers::Operator.new(compiler_options(options, structure)).compile
    end

    # u: [:name, :email], _feedbacks_count: {select ...},
    # _total_sum: [:_sum, :amount, :cost]
    def compile_expressions(structure, options = {})
      Compilers::Expression.new(compiler_options(options, structure)).compile
    end

    module_function :compile_sql, :compile_clause, :compile_clauses,
                    :compile_expressions, :compile_operators

    private

    def compiler_params
      { params: CompilerParams.new }
    end

    def compiler_options(options = {}, structure = nil)
      options[:params] ||= CompilerParams.new
      options[:structure] ||= structure
      options
    end
    module_function :compiler_params, :compiler_options
  end
end
