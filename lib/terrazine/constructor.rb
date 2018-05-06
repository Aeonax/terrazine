module Terrazine
  class Constructor
    attr_reader :structure, :params
    def initialize(structure = {})
      @structure = structure
    end

    # TODO? join hash inside array?
    # TODO!! join values of existing keys on hashes merge
    def structure_constructor(structure, modifier)
      return modifier unless structure

      if structure.is_a?(Hash) && modifier.is_a?(Hash)
        modifier.each do |k, v|
          structure[k] = structure_constructor(structure[k], v)
        end
        structure
      else
        structure = structure.is_a?(Array) ? structure : [structure]
        if modifier.is_a?(Array)
          modifier.each { |i| structure_constructor structure, i }
        else
          structure << modifier
        end
        structure.uniq
      end
    end

    def select(structure)
      @structure[:select] = structure_constructor(@structure[:select], structure)
      self
    end

    def distinct(fields = true)
      @structure[:distinct] = fields
      self
    end

    def distinct_select(structure, fields = true)
      @structure[:distinct] = fields
      select structure
      self
    end

    # TODO: from construction
    # from [:mrgl, :m]
    # from [:_values, [1, 2], :rgl, [:zgl, :gl]]
    # => [[:mrgl, :m], [:_values, [1, 2], :rgl, [:zgl, :gl]]]
    def from(structure)
      @structure[:from] = structure
      self
    end

    # TODO: join constructor AND better syntax
    def join(structure)
      @structure[:join] = structure
      self
    end

    def where(structure)
      w = @structure[:where]
      if w.is_a?(Array) && w.first.is_a?(Array)
        @structure[:where].push structure
      elsif w
        @structure[:where] = [w, structure]
      else
        @structure[:where] = structure
      end
      self
    end

    # TODO: with constructor -_-
    def with(structure)
      @structure[:with] = structure
      self
    end

    # TODO: order constructor -_-
    def order(structure)
      @structure[:order] = structure
      self
    end

    # TODO: default per used here and in builder...-_-
    def limit(per)
      @structure[:limit] = (per || 8).to_i
      self
    end

    # same as limit =(
    def offset(offset)
      @structure[:offset] = offset || 0
    end

    # TODO: serve - return count of all rows
    # params - hash with keys :per, :page
    def paginate(params)
      limit params[:per]
      offset((params.fetch(:page, 1).to_i - 1) * @structure[:limit])
      self
    end

    # just rewrite data. TODO: merge with merge without loss of data?
    # constructor.merge(select: :content, order_by: 'f.id DESC', limit: 1)
    def merge(params)
      @structure.merge! params
      self
    end

    # constructor.build_sql
    # => 'SELECT .... FROM ...'
    # => ['SELECT .... FROM .... WHERE id = $1', [22]]
    def build_sql(options = {})
      Builder.new.get_sql @structure, options
    end
  end
end
