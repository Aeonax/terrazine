# frozen_string_literal: true

module Terrazine
  # Public interface for interaction with Compilers
  module Compiler
    # { select: ..., from: ... }
    def compile_sql(structure, options = {})
      Compilers::Clause.new(compiler_options(options, structure)).compile
    end
    alias compile_clauses compile_sql

    # :select, { u: [:name, :email] }
    def compile_clause(name, &values)
      Compilers::Clause.new(compiler_params).send(name, values)
    end

    # select: {..}, from: [...]
    # def compile_clauses(structure, options = {})
    #   Compilers::Clause.new(compiler_options(options)).compile(structure)
    # end

    # :eq, :u__name, 'Aeonax'
    def compile_condition(name, &values)
      Compilers::Condition.new(compiler_params).send(name, values)
    end

    # { u__name: 'Aeonax' }
    def compile_conditions(structure, options = {})
      Compilers::Condition.new(compiler_options(options, structure)).compile
    end

    # (:sum, :amount, :cost)
    def compile_operator(name, &values)
      Compilers::Operator.new(compiler_params).send(name, values)
    end

    # u: [:name, :email], _feedbacks_count: {select ...},
    # _total_sum: [:_sum, :amount, :cost]
    def compile_expressions(structure, options = {})
      Compilers::Expression.new(compiler_options(options, structure)).compile
    end

    private

    def compiler_params
      { params: CompilerParams.new }
    end

    def compiler_options(options = {}, structure = nil)
      options[:params] ||= compiler_params
      options[:structure] ||= structure
      options
    end
  end
end
