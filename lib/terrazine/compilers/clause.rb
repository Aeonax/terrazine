# frozen_string_literal: true

module Terrazine
  module Compilers
    class Clause < Base
      def compile(*structure)
        sql = ''

        # shit... I wanna skip that iteration so much...
        # how it could be relocated in to separate method without
        # raise in that method or variable && dublicated conditions here...
        union_data = initial_or_(structure, :union)
        return union(*union_data) if union_data

        [:with, :select, :insert, :update, :delete, :set, :from, :join,
         :having, :where, :returning, :group, :order, :limit, :offset].each do |i|
          next unless initial_or_(structure, i)
          sql += send(i)
        end
        sql
      end

      def with(*structure)
        AdvancedCompilers::With.new(options).build(initial_or_(structure, :with))
      end

      def union(*structure)
        return unless structure
        structure.map { |s| compile(s) }.join ' UNION '
      end

      def select(*structure)
        # select_data = strucutre.empty? ? initial_structure[:select] : structure
        "SELECT #{distinct(d_structure)}#{expressions(initial_or_(structure, :select))} "
      end

      def distinct(*structure)
        data = initial_or_(structure, :distinct)
        return unless data
        return 'DISTINCT ' if data.first.is_a?(TrueClass)

        "DISTINCT ON(#{expressions data}) "
      end

      # For use via `Compiler.compile_clause(:distinct_select, {...}, true)`
      def distinct_select(select_structure, distinct_structure = true)
        select(select_structure, distinct_structure)
      end

      def from(*structure)
        "FROM #{tables(initial_or_(structure, :from))} "
      end

      def join(*structure)
        AdvancedCompilers::Join.new(options).build(initial_or_(structure, :join))
      end

      # TODO!!!
      def update(*structure)
        AdvancedCompilers::Update.new(options).build(initial_or_(structure, :update))
      end

      def returning(*structure)
        # TODO? expressions may be redundant and columns parsing would be enought
        "RETURNING #{expressions(initial_or_(structure, :returning))}"
      end

      def where(*structure)
        "WHERE #{build_conditions(initial_or_(structure, :where))} "
      end

      def having(*structure)
        "WHERE #{build_conditions(initial_or_(structure, :where))} "
      end

      def order(*structure)
        AdvancedCompilers::Order.new(options).build(initial_or_(structure, :order))
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
