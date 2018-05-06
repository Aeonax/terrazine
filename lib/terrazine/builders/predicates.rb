module Terrazine
  class Builder
    # TODO: :between, :!=, :>, :<, :>=, :<=
    # Done: :eq, :not, :or, :and, :like, :ilike, :reg_#{type}, :in

    # now it doesn't use Operators
    # uses Expressions

    private

    # TODO? conditions like [:eq :name :Aeonax]
    def build_predicates(structure)
      construct_condition(structure, true)
    end

    # [:or, { u__name: 'Aeonax', u__role: 'liar'}, # same as [[:eq, :u__name, 'Aeonax'], ...]
    #       [:not, [:in, :id, [1, 2, 531]]]]
    def construct_condition(structure, first_level = nil)
      case structure
      when Array
        key = structure.first
        return construct_condition(key) if structure.size < 2
        if key.is_a? Symbol
          parentizer send("condition_#{key}", structure.drop(1)), first_level, key
        elsif key.is_a?(String) && key =~ /\?/
          if [Hash, Constructor].include?(structure.second.class)
            key.sub(/\?/, "(#{build_sql(structure.second)})")
          else
            key.sub(/\?/, build_param(structure.second))
          end
        else
          parentizer condition_and(structure), first_level, :and
        end
      when Hash
        res = condition_eq structure
        first_level ? condition_and(res) : res
      when Symbol
        condition_column(structure)
      when String
        structure
      else
        raise "Unknow structure #{structure} class #{structure.class} for condition"
      end
    end

    # common

    def condition_column(structure)
      structure.to_s.sub(/__/, '.')
    end

    def construct_condition_value(structure)
      case structure
      when Symbol
        condition_column(structure)
      when TrueClass, FalseClass
        structure.to_s.upcase
      when nil
        'NULL'
      else
        build_param structure
      end
    end

    def parentizer(sql, first_level, key)
      if first_level || ![:or, :and].include?(key)
        sql
      else
        "(#{sql})"
      end
    end

    #### Condition builders

    # supporting eq if there is no array inside
    def condition_not(structure)
      value = if structure.count == 1
                construct_condition structure.flatten(1)
              else
                condition_eq structure
              end
      "NOT #{value}"
    end

    def conditions_joiner(structure, joiner)
      structure.map { |i| construct_condition i }.flatten.join(" #{joiner} ".upcase)
    end

    def condition_and(structure)
      conditions_joiner structure, 'and'
    end

    def condition_or(structure)
      conditions_joiner structure, 'or'
    end

    def condition_in(structure)
      values = case structure.second
               when Hash, Constructor
                 build_sql structure.second
               else
                 build_param structure.second
               end
      "#{construct_condition_value structure.first} IN (#{values})"
    end

    def conditions_construct_eq(column, value)
      return condition_in([column, value]) if value.is_a? Array
      "#{construct_condition_value column} = #{construct_condition_value value}"
    end

    def condition_is(structure)
      "#{construct_condition_value structure.first} IS #{construct_condition_value structure.second}"
    end

    def condition_eq(structure)
      case structure
      when Array
        conditions_construct_eq structure.first, structure.second
      when Hash
        iterate_hash(structure, false) { |k, v| conditions_construct_eq k, v }
      else
        raise "Undefinded structure: #{structure} for equality condition builder"
      end
    end

    def condition_between(structure)
      "BETWEEN #{construct_condition structure}"
    end

    def condition_pattern(structure, pattern)
      "#{construct_condition_value structure.first} #{pattern.upcase} " \
      "#{construct_condition_value structure.second}"
    end

    def condition_like(structure)
      condition_pattern structure, :like
    end

    def condition_ilike(structure)
      condition_pattern structure, :ilike
    end

    def condition_reg(structure)
      condition_pattern structure, '~'
    end

    def condition_reg_i(structure)
      condition_pattern structure, '~*'
    end

    def condition_reg_f(structure)
      condition_pattern structure, '!~'
    end

    def condition_reg_fi(structure)
      condition_pattern structure, '!~*'
    end
  end
end
