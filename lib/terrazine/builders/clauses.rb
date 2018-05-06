module Terrazine
  class Builder
    # it use Predicate, expressions

    private

    # TODO: :with_recursive
    def build_with(structure, _)
      "WITH #{construct_with(structure)} "
    end

    def build_union(structure, _)
      structure.map { |i| build_sql(i) }.join ' UNION '
    end

    def build_select(structure, common_structure)
      distinct = construct_distinct common_structure[:distinct]
      "SELECT #{distinct}#{build_columns structure} "
    end

    def build_from(structure, _)
      "FROM #{build_tables(structure)} "
    end

    # TODO: -_-
    def build_join(structure, _)
      if structure.is_a? Array
        # TODO: hash is sux here -_- !!!!!!
        if structure.second.is_a? Hash
          name = build_tables structure.first # (name.is_a?(Array) ? name.join(' ') : name)
          v = structure.second
          "#{v[:option].to_s.upcase + ' ' if v[:option]}JOIN #{name} ON #{build_predicates v[:on]} "
        else
          structure.map { |i| build_join(i, nil) }.join
        end
      else
        structure =~ /join/i ? structure : "JOIN #{structure} "
      end
    end

    # TODO!
    def build_update(structure, _)
      "UPDATE #{construct_update structure} "
    end

    def build_returning(structure, _)
      "RETURNING #{build_columns structure}"
    end

    def build_where(structure, _)
      "WHERE #{build_predicates(structure)} "
    end

    # TODO!
    def build_order(structure, _)
      "ORDER BY #{construct_order structure} "
    end

    def build_limit(limit, _)
      "LIMIT #{limit || 8} "
    end

    def build_offset(offset, _)
      "OFFSET #{offset || 0} "
    end

    def construct_with(structure)
      case structure
      when Array
        if structure.second.is_a? Hash
          "#{structure.first} AS (#{build_sql(structure.last)})"
        else
          structure.map { |v| construct_with(v) }.join ', '
        end
      when Hash
        iterate_hash(structure) { |k, v| "#{k} AS (#{build_sql v})" }
      else
        raise
      end
    end

    def construct_distinct(structure)
      return unless structure
      if structure == true
        'DISTINCT '
      else
        "DISTINCT ON(#{build_columns structure}) "
      end
    end

    def construct_update(structure)
      case structure
      when Array
        table = build_tables structure.first
        "#{table} SET #{construct_set structure.last}"
      when String
        structure
      else
        raise "Undefined structure for `UPDATE`: #{structure}"
      end
    end

    # TODO: (..., ...) = (..., ...)
    def construct_set(structure)
      case structure
      when Hash
        iterate_hash(structure) { |k, v| "#{build_columns k} = #{build_columns v}" }
      when String
        structure
      else
        raise "Undefined structure for `UPDATE`: #{structure}"
      end
    end

    # { name: :asc, email: [:desc, :last] }
    # [:name, :email, { phone: :last }]
    def construct_order(structure)
      case structure
      when Array # function or values for order
        if check_alias structure.first
          build_operator structure
        else
          structure.map { |i| construct_order i }.join ', '
        end
      when Hash
        iterate_hash(structure) { |k, v| "#{construct_order k} #{construct_order_options v}" }
      else
        structure
      end
    end

    def construct_order_options(option)
      case option
      when Array
        option.sort.map { |i| construct_order_options i }.join ' '
      when :last, :first
        "nulls #{option}".upcase
      when :asc, :desc
        option.to_s.upcase
      else
        "USING#{option}"
      end
    end
  end
end
