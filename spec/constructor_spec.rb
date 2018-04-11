require_relative 'spec_helper'

# TODO.... -_-
# May be store structures with string representation? Because tests sux right now=(
describe Terrazine::Constructor do
  before :each do
    @constructor = Terrazine.new_constructor
  end
  before :all do
    @permanent_c = Terrazine.new_constructor
  end

  it 'mrgl' do
    expect(@constructor.class).to eql Terrazine::Constructor
  end

  context '`WITH`' do
    it 'build array like syntax' do
      @constructor.with [:name, { select: true }]
      expect(@constructor.build_sql).to eq 'WITH name AS (SELECT * ) '
    end

    it 'build nested array like syntax' do
      @constructor.with [[:name, { select: true }],
                         [:another_name, { select: :mrgl }]]
      expect(@constructor.build_sql).to eq 'WITH name AS (SELECT * ), another_name AS (SELECT mrgl ) '
    end

    it 'build hash like syntax' do
      @constructor.with name: { select: true },
                        another_name: { select: :mrgl }
      expect(@constructor.build_sql).to eq 'WITH name AS (SELECT * ), another_name AS (SELECT mrgl ) '
    end
  end

  context '`SELECT`' do
    it 'build simple structure' do
      @constructor.select(:name)
      @constructor.select('phone')
      expect(structure(:select)).to eql [:name, 'phone']
    end

    it 'build hash structure' do
      @constructor.select(u: [:name, :email])
      @constructor.select _calls_count: [:_count, :connected]
      expect(structure(:select)).to eq  u: [:name, :email],
                                        _calls_count: [:_count, :connected]
      expect(@constructor.build_sql).to eq 'SELECT u.name, u.email, COUNT(connected) AS calls_count '
    end

    it 'build sub_queries' do
      @constructor.select select: [:_count, [:_nullif, :connected, true]],
                          from: [:calls, :c],
                          where: 'u.id = c.user_id'
      expect(@constructor.build_sql).to eq 'SELECT (SELECT COUNT(NULLIF(connected, true)) FROM calls c WHERE u.id = c.user_id ) '
    end

    it 'build big structures' do
      @permanent_c.select _calls_count: { select: [:_count, [:_nullif, :connected, true]],
                                          from: [:calls, :c],
                                          where: { u__id: :c__user_id } },
                          u: [:name, :phone, { _master: [:_nullif, :role, "'master'"] },
                              'u.abilities, u.id', 'birthdate']
      @permanent_c.select o: :client_name
      @permanent_c.select :secure_id
      expect(@permanent_c.build_sql).to eq "SELECT (SELECT COUNT(NULLIF(connected, true)) FROM calls c WHERE u.id = c.user_id ) AS calls_count, u.name, u.phone, NULLIF(u.role, 'master') AS master, u.abilities, u.id, u.birthdate, o.client_name, secure_id "
    end

    it 'build DISTINCT' do
      @constructor.distinct_select([:id, :name, :phone])
      expect(@constructor.build_sql).to eq 'SELECT DISTINCT id, name, phone '
    end

    it 'build DISTINCT ON field' do
      @constructor.distinct_select([:id, :name, :phone], :id)
      expect(@constructor.build_sql).to eq 'SELECT DISTINCT ON(id) id, name, phone '
    end

    it 'build DISTINCT ON array of field' do
      @constructor.distinct_select([:id, :name, :phone], [:id, :phone])
      expect(@constructor.build_sql).to eq 'SELECT DISTINCT ON(id, phone) id, name, phone '
    end
  end

  context '`FROM`' do
    it 'build simple data structures' do
      @constructor.from :users
      expect(@constructor.build_sql).to eq 'FROM users '
      @permanent_c.from [:users, :u]
      expect(@permanent_c.build_sql).to match 'o.client_name, secure_id FROM users u $'
    end

    it 'build VALUES' do
      @constructor.from [:_values, [:_params, 'mrgl'], :r, ['type']]
      expect(@constructor.build_sql).to eq ['FROM (VALUES($1)) AS r (type) ', ['mrgl']]
    end

    it 'build VALUES and tables' do
      @constructor.from [[:mrgl, :m], [:_values, [1, 2], :rgl, [:zgl, :gl]]]
      expect(@constructor.build_sql).to eq 'FROM mrgl m, (VALUES(1, 2)) AS rgl (zgl, gl) '
    end

    it 'build VALUES with many rows' do
      @constructor.from [:_values, [[:_params, 'mrgl'], [:_params, 'rgl']], :r, ['type']]
      expect(@constructor.build_sql).to eq ['FROM (VALUES($1), ($2)) AS r (type) ',
                                            ['mrgl', 'rgl']]
    end
  end

  context '`JOIN`' do
    it 'build simple structure' do
      @constructor.join 'users u ON u.id = m.user_id'
      expect(@constructor.build_sql).to eq 'JOIN users u ON u.id = m.user_id '
      @constructor.join ['users u ON u.id = m.user_id',
                         'skills s ON u.id = s.user_id']
      expect(@constructor.build_sql).to eq 'JOIN users u ON u.id = m.user_id JOIN skills s ON u.id = s.user_id '
    end

    it 'build big structures' do
      @permanent_c.join [[[:masters, :m], { on: 'm.user_id = u.id' }],
                         [[:attachments, :a], { on: ['a.user_id = u.id',
                                                     'a.type = 1'],
                                                option: :left}]]
      expect(@permanent_c.build_sql).to match 'FROM users u JOIN masters m ON m.user_id = u.id LEFT JOIN attachments a ON a.user_id = u.id AND a.type = 1 $'
    end
  end

  context '`ORDER`' do
    it 'build string structre' do
      @constructor.order 'name ASC'
      expect(@constructor.build_sql).to eq 'ORDER BY name ASC '
    end

    it 'build array structure' do
      @constructor.order [:name, :email]
      expect(@constructor.build_sql).to eq 'ORDER BY name, email '
    end

    it 'build hash structure' do
      @constructor.order name: :asc, phone: [:first, :desc]
      expect(@constructor.build_sql).to eq 'ORDER BY name ASC, phone DESC NULLS FIRST '
    end

    it 'build complicated structure' do
      @constructor.order [:role, { name: :asc, phone: [:last, :desc], amount: '<' }]
      expect(@constructor.build_sql).to eq 'ORDER BY role, name ASC, phone DESC NULLS LAST, amount USING< '
    end
  end

  context '`WHERE`' do
    it 'build simple structure' do
      @constructor.where ['NOT z = 13',
                          [:or, 'mrgl = 2', 'rgl = 22'],
                          [:or, 'rgl = 12', 'zgl = lol']]
      expect(@constructor.build_sql).to eq 'WHERE NOT z = 13 AND (mrgl = 2 OR rgl = 22) AND (rgl = 12 OR zgl = lol) '
    end

    it 'build intemidate structure' do
      @constructor.where [{ role: 'manager', id: [0, 1, 153] },
                          [:not, [:like, :u__name, 'Aeonax']]]
      expect(@constructor.build_sql).to eq ['WHERE role = $1 AND id IN ($2) AND NOT u.name LIKE $3 ', ['manager', [0, 1, 153], 'Aeonax']]
    end
  end
end
