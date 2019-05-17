# frozen_string_literal: true

require_relative 'advanced_clauses/join'
require_relative 'advanced_clauses/values'
require_relative 'advanced_clauses/with'

module Terrazine
  module Compilers
    class Clause < Base
      def compile(structure = initial_structure)
        sql = ''
        structure = structure.structure if constructor?(structure)

        union_data = structure[:union]
        return union(*union_data) if union_data

        [:with, :select, :insert, :values, :update, :delete, :set, :from, :join,
         :having, :where, :returning, :group, :order, :limit, :offset].each do |i|
          sql += send(i, structure[i]) if structure[i]
        end
        sql
      end

      def with(*structure)
        AdvancedClauses::With.new(@options).build(structure)
      end

      def union(structure)
        return if structure.empty?
        structure.map { |s| compile(s) }.join ' UNION '
      end

      # {select: { a: [:z] }}
      def select(*structure)
        "SELECT #{distinct}#{expressions(initial_or_(structure, :select))} "
      end

      # { distinct: {a: [:z]} }
      def distinct(*data)
        structure = initial_or_(data, :distinct)
        return if structure.nil? || structure.empty?
        return 'DISTINCT ' if structure.first.is_a?(TrueClass)

        "DISTINCT ON(#{expressions(structure)}) "
      end

      # For use via `Compiler.compile_clause(:distinct_select, {...}, field(s))`
      def distinct_select(select_structure, distinct_structure = true)
        select(select_structure, distinct_structure)
      end

      def values(*structure)
        AdvancedClauses::Values.new(@options).build(initial_or_(structure, :join))
      end

      def from(*structure)
        "FROM #{tables(initial_or_(structure, :from))} "
      end

      def join(*structure)
        AdvancedClauses::Join.new(options).build(initial_or_(structure, :join))
      end

      # TODO!!!
      def update(*structure)
        AdvancedCompilers::Update.new(options).build(initial_or_(structure, :update))
      end

      def returning(*structure)
        # TODO? expressions may be redundant and columns parsing would be enought
        "RETURNING #{expressions(initial_or_(structure, :returning))} "
      end

      def where(*structure)
        "WHERE #{build_conditions(initial_or_(structure, :where))} "
      end

      def having(*structure)
        "WHERE #{build_conditions(initial_or_(structure, :where))} "
      end

      def order(*structure)
        AdvancedClauses::Order.new(options).build(initial_or_(structure, :order))
      end

      def limit(count)
        "LIMIT #{count} "
      end

      def offset(count)
        "OFFSET #{count} "
      end
    end
  end
end
