require_relative 'spec_helper'

# TODO.... -_-
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

  context '`select`' do
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
      expect(@constructor.build_sql).to eq 'SELECT (SELECT COUNT(NULLIF(connected, true)) FROM calls c WHERE u.id = c.user_id  ) '
    end

    it 'build big structures' do
      @permanent_c.select _calls_count: { select: [:_count, [:_nullif, :connected, true]],
                                          from: [:calls, :c],
                                          where: 'u.id = c.user_id' },
                          u: [:name, :phone, { _master: [:_nullif, :role, "'master'"] },
                              'u.abilities, u.id', 'birthdate']
      @permanent_c.select o: :client_name
      @permanent_c.select :secure_id
      expect(@permanent_c.build_sql).to eq "SELECT (SELECT COUNT(NULLIF(connected, true)) FROM calls c WHERE u.id = c.user_id  ) AS calls_count, u.name, u.phone, NULLIF(u.role, 'master') AS master, u.abilities, u.id, u.birthdate, o.client_name, secure_id "
    end
  end

  context '`from`' do
    it 'build simple data structures' do
      @constructor.from :users
      expect(@constructor.build_sql).to eq 'FROM users '
      @permanent_c.from [:users, :u]
      expect(@permanent_c.build_sql).to match 'o.client_name, secure_id FROM users u $'
    end

    it 'build values' do
      @constructor.from [:_values, [:_param, 'mrgl'], :r, ['type']]
      expect(@constructor.build_sql).to eq ['FROM (VALUES($1)) AS r (type) ', ['mrgl']]
    end

    it 'build values and tables' do
      @constructor.from [[:mrgl, :m], [:_values, [1, 2], :rgl, [:zgl, :gl]]]
      expect(@constructor.build_sql).to eq 'FROM mrgl m, (VALUES(1, 2)) AS rgl (zgl, gl) '
    end
  end

  context '`join`' do
    it 'build simple join' do
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

  context '`conditions`' do
    
  end
end
