module Terrazine
  class Constructor
    attr_reader :structure, :params
    def initialize(structure = {})
      @structure = structure
      # @params = []
      @builder = Builder.new(self)
    end

    # TODO? join hash inside array?
    # TODO!! join values of existing keys
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

    # just string
    ### select "name, email"

    # array of strings or symbols
    ### select [*selectable_fields]

    # hash with column aliases
    ### select _field_alias: :field
    ### => 'SELECT field AS field_alias '

    # array of fields and aliases - order doesnt matter
    ### select [{ _user_id: :id, _user_name: :name }, :password]
    ### => 'SELECT id AS user_id, name AS user_name, password '

    # functions - array with first value - function name with underscore as symbol
    ### select [:_nullif, :row, :value]

    # table alias/name
    ### select t_a: [{ _user_id: :id }, :field_2, [:_nullif, :row, :value]]
    ### => 'SELECT t_a.id AS user_id, t_a.password, NULLIF(t_a.row, value) '

    # any nesting and sub queries as new SQLConstructor or hash structure
    ### select u: [{ _some_count: [:_count, [:_nullif, :row, :value]] },
    ###            :name, :email],
    ###        _u_count: (another_constructor || another_structure)
    ### => 'SELECT COUNT(NULLIF(u,row, value)) AS some_count, u.name, u.email, (SELECT ...) AS u_count '

    # construct it
    ### constructor = SQLConstructor.new from: [:users, :u],
    ###                                  join [[:mrgl, :m], { on: 'm.user_id = u.id'}]
    ### constructor.select :name
    ### constructor.select [{u: :id, _some_count: [:_count, another_constructor]}] if smthng
    ### constructor.select [{r: :rgl}, :zgl] if another_smthng
    ### constructor.build_sql
    ### => 'SELECT name, u.id, COUNT(SELECT ...) AS some_count, r.rgl, zgl FROM ...'
    def select(structure)
      @structure[:select] = structure_constructor(@structure[:select], structure)
      self
    end

    # distinct_select select_structure
    # distinct_select select_structure, distinct_field
    # distinct_select select_structure, [*distinct_fields]
    def distinct_select(structure, fields = nil)
      @structure[:distinct] = fields || true
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
    # join 'users u ON u.id = m.user_id'
    # join ['users u ON u.id = m.user_id',
    #       'skills s ON u.id = s.user_id']
    # join [[:user, :u], { on: 'rgl = 123' }]
    # join [[[:user, :u], { option: :full, on: [:or, 'mrgl = 2', 'rgl = 22'] }],
    #       [:master, { on: ['z = 12', 'mrgl = 12'] }]]
    def join(structure)
      @structure[:join] = structure
      # puts @structure[:join]
      self
    end

    # conditions 'mrgl = 12'
    # conditions ['z = 12', 'mrgl = 12']
    # conditions ['NOT z = 13', [:or, 'mrgl = 2', 'rgl = 22']]
    # conditions [:or, ['NOT z = 13', [:or, 'mrgl = 2', 'rgl = 22']],
    #                  [:or, 'rgl = 12', 'zgl = fuck']]
    # conditions [['NOT z = 13',
    #             [:or, 'mrgl = 2', 'rgl = 22']],
    #             [:or, 'rgl = 12', 'zgl = fuck']]
    # => 'NOT z = 13 AND (mrgl = 2 OR rgl = 22) AND (rgl = 12 OR zgl = fuck)'
    # conditions ['NOT z = 13', [:or, 'mrgl = 2',
    #                                 ['rgl IN ?', {select: true, from: :users}]]]

    # constructor.where ['u.categories_cache ~ ?',
    #                           { select: :path, from: :categories,
    #                             where: ['id = ?', s_params[:category_id]] }]
    # constructor.where('m.cashless IS TRUE')
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

    # TODO: with -_-
    # with [:alias_name, { select: true, from: :users}]
    # with [[:alias_name, { select: true, from: :users}],
    #       [:alias_name_2, { select: {u: [:name, :email]},
    #                         from: :rgl}]]

    def limit(per)
      @structure[:limit] = (per || 8).to_i
      self
    end

    # TODO: serve - return count of all rows
    # params - hash with keys :per, :page
    def paginate(params)
      limit params[:per]
      @structure[:offset] = ((params[:page]&.to_i || 1) - 1) * @structure[:limit]
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
    def build_sql
      @builder.get_sql @structure
    end
  end
end
