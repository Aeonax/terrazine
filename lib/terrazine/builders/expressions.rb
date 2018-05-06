module Terrazine
  class Builder

    # doesn't use Predicates
    # use Operators, Expressions

    private

    # TODO: split
    def build_tables(structure)
      case structure
      when Array
        if check_alias(structure.first) # VALUES function or ...?
          build_operator(structure)
        # if it's a array with strings/values || array of tables/values
        else
          joiner = structure.select { |i| i.is_a? Array }.empty? ? ' ' : ', '
          structure.map { |i| build_tables i }.join joiner
        end
      when Hash
        "(#{build_sql structure})"
      when String, Symbol
        structure
      else
        raise "Undefined structure for FROM - #{structure}"
      end
    end

    # TODO: split
    def build_columns(structure, prefix = nil)
      case structure
      when Array
        # SQL function - in format: "_#{fn}"
        if check_alias(structure.first)
          build_operator structure, prefix
        else
          structure.map { |i| build_columns i, prefix }.join ', '
        end
      when Hash
        # sub_query
        if structure[:select]
          "(#{build_sql(structure)})"
        # colum OR table alias
        else
          iterate_hash(structure) do |k, v|
            if check_alias(k)
              # update ruby for delete_prefix? =)
              "#{build_columns(v, prefix)} AS #{k.to_s.sub(/^_/, '')}"
              # construct_as(build_columns(v, prefix), k)
            else
              build_columns(v, k.to_s)
            end
          end
        end
      when Symbol, String, Integer
        structure = structure.to_s
        if prefix && structure !~ /, |\.|\(/
          "#{prefix}.#{structure}"
        else
          structure
        end
      when Constructor
        "(#{build_sql structure.structure})"
      when true # choose everything -_-
        build_columns('*', prefix)
      else # TODO: values from value passing here... -_-
        structure
        # raise "Undefined class: #{structure.class} of #{structure}" # TODO: ERRORS class
      end
    end
  end
end
