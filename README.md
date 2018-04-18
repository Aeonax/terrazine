# Terrazin

## Idea
Simple and comfortable, as possible, data structures parser in to SQL.  

#### Data
Describing sql with data structures like [honeysql](https://github.com/jkk/honeysql) or [ql](https://github.com/niquola/ql) in clojure.  

#### Constructor
Construct data structures inside Constructor instance.

#### Result
Get result and access any returned data rails like syntax.

#### Realization
This is my first gem and first close meeting with OOP... I would appreciate any help =)
And sorry for my English =(  

#### Readiness
Terrazine is not finished yet. Now it has allmost full SELECT builder, but with some limitations like:
- awfull where syntax
- bad join syntax
- not all SQL functions supported  

And now it supports only Postgresql.

## Detailed description

### Usage
#### Initialization
Add this line to the Gemfile  
```ruby
gem 'terrazine', '0.0.2'
```  
After server initialization set `Terrazine.config`. Now config accepts only `:connection` option. In the bright future will be added `:adapter` option support.  
In rails you can set config with [after_initialize](https://apidock.com/rails/Rails/Configuration/after_initialize) and it will looks like:  

UPD: On production, rails closing `PG::Connection` from `after_initialize`, as fast fix connection now can be `Proc` object which must return `PG::Connection`. Later i'll try to find better solution  
```ruby
# file config/application.rb
module Name
  class Application < Rails::Application
  # ....
    config.after_initialize do
      Terrazine.config connection: -> { ActiveRecord::Base.connection.raw_connection }
    end
  # ....
  end
end
```  
#### Workflow
- Describe whole data structure, or create `Constructor` instance and combine parts of data by it instance methods. 
- Send result to `Terrazine.send_request(structure||constructor, params = {})` 
- Rejoice at the `::Result`

### Constructor
You can create Constructor instance by calling `Terrazine.new_constructor`. It optional accepts data structure.  
```ruby
constructor = Terrazine.new_constructor
constructor_2 = Terrazine.new_constructor from: :calls
```  
#### Instance methods
Instance methods write or combine data inside constructor instance.
Not finished methods - just rewrites structure without combination with existing data.  
- [ ] with
- [x] select/distinct_select
- [ ] from
- [ ] join
- [x] where
- [x] limit
- [x] paginate
- [x] merge - just merging instance structure with argument
- [x] build_sql

### Data Structures
You can take a look on more detailed examples in `spec/constructor_spec.rb`

#### Common patterns
###### SQL Function
Structure:
- `Array`
  - first element - `Symbol` that begins from _ - `:_nullif`
  - arguments
    - [columns](#columns)  

```ruby
[:_count, [:_nullif, :row, [:_params, 'mrgl']]] # TODO: param?
# => ['COUNT(NULLIF(row, $1))', ['mrgl']]
```  
[Detailed Functions description](#sql-functions).  
###### Columns
Possible structures:
- `String`
  - if it locted in the `Hash` with table alias, table alias will be added to it
  - if there is no table alias it will be returned to the builder as it is.
- `Symbol` - just parsed to string
- `Hash`
  - key - table alias||name
  - value - [columns](#columns)
- [SQL function](#sql-function)
- `Array` - holder of any possible structures  
```ruby
['name', {u: ['role', 'u.phone, m.rating', :field]}]
# => 'name, u.role, u.phone, m.rating, u.field'
```  
[Detailed Select description](#select)
###### Tables
Possible structures:
- `String` || `Symbol`
- [SQL function](#sql-function)
- `Array`
  - if there is no `Array` inside it will be joined `structure.join ' '`
  - otherwise it will be recursive mapped  
```ruby
['users u', [:_values, ...], [:masters, :m]]
'users u, (VALUES...), masters m'
```   
###### Conditions
Not finished yet...
Column can be described as `:u__name => 'u.name'` or `:name`
Possible structures:
- `String` passes as it is
- `Hash` represent sql `=` or `IN` if value is `Array`. TODO: `IS` in case of `nil` or `false`
  - `Symbol` - column name
  - `Array` - only as value! will be placed in querry params `($1)`.
  - `String` - will be placed in querry params
- `Array`
  - first element - `Symbol` operator representation, by default `:and`
    - `eq` - `=`
    - `or`, `and`
    - `in`
    - `not`
    - `like`, `ilike`
    - `reg` - `~`, `reg_i` - `~*`, `reg_f` - `!~`, `reg_fi` - `!~*`
  - arguments
- `Array` - holder of any possible structures  
```ruby
[[:not, 'z = 13'],
 [:or, 'mrgl = 2', 'rgl = 22'],
 [:or, 'rgl = 12', 'zgl = lol']]
# => 'NOT z = 13 AND (mrgl = 2 OR rgl = 22) AND (rgl = 12 OR zgl = lol)'
[{ role: 'manager', id: [0, 1, 153] },
 [:not, [:like, :u__name, 'Aeonax']]]
#=> 'role = $1 AND id IN ($2) AND NOT u.name LIKE $3', ['manager', [0, 1, 153], 'Aeonax']
```  
###### Sub Querry
Possible structures:
- `Constructor` instance
- `Hash` with `:select` value  

#### Select
Possible structures:
- [columns](#columns)
- [sub querry](#sub-query)
- [SQL function](#sql-function)
- `Array` with combination of possible structures.  
```ruby
# String
constructor.select "name, email"
# Symbol
constructor.select :birthdate
# Array as columns
constructor.select [:phone, 'role']
# Array as SQL function
constructor.select [:_nullif, :row, :value]
# Hash with column alias(`AS`) as key and any available for `select` value
constructor.select _missed_calls_count:
                     { select: [:_count, [:_nullif, :connected, :true]],
                       from: [:calls, :c],
                       where: ['c.client_id = u.id',
                               ['direction = ?', 0]]}
# Hash with table alias as key and any available for `select` values
constructor.select m: [:common_rating, :work_rating, { _master_id: :id }]
# You can take a look of resulted data structure. In future, perhaps, Constructor will be more complicated and it will merge hashes...
constructor.structure
# => { select: ['name, email', :birthdate, :phone, 'role',
#               [:_nullif, :row, :value],
#               { _missed_calls_count: { select: [:_count, [:_nullif, :connected, :true]],
#                                        from: [:calls, :c],
#                                        where: ['c.client_id = u.id',
#                                                ['direction = ?', 0]]} }] },
#               { m: [:common_rating, :work_rating, { _master_id: :id }] }

constructor.build_sql
# => ['SELECT name, email, birthdate, phone, role, NULLIF(row, value), m.common_rating, m.work_rating, m.id AS master_id,
#             (SELECT COUNT(NULLIF(connected, TRUE))
#              FROM calls c
#              WHERE c.client_id = u.id AND direction = $1) AS missed_calls_count',
#     0]
```  

##### Distinct Select
To specify distinct select you should add to your data structure `:distinct` value:
- `true`
- [columns](#columns)  
Or with `Constructor` instance methods:
- `.distinct`
  - distinct structure - optional
- `.distinct_select`
  - [select](#select) structure
  - distinct structure - optional
In constructor methods `distinct: true` passed by default  
```ruby
# as data
distinct: true, select: true
# => 'SELECT DISTINCT * '
# OR via constructor
constructor.distinct_select([:id, :name]).build_sql # => 'SELECT DISTINCT id, name'
# OR
constructor.distinct_select([:id, :name], :phone).build_sql # => 'SELECT DISTINCT ON(phone) id, name '
```  

#### From
Possible structures:
- [table representation](#tables)
- [SQL functions](#sql-functions)
- `Array` with combination of possible structures.  
```ruby
from: 'table_name table_alias' || :table_name
from: [:table_name, :table_alias]
# => 'FROM table_name table_alias '
from: [:_values, [1, 2], :rgl, [:zgl, :gl]]
# => 'FROM (VALUES(1, 2)) AS rgl (zgl, gl)'
from: [[:table_name, :table_alias], [:_values, [1, 2], :values_name, [*values_column_names]]]
# => 'FROM table_name table_alias, (VALUES(1, 2)) AS values_name (v_c_1, v_c_2)'
```  
I do not like the `from` syntax, but how it can be made more convenient...?

#### Join
Possible structures:
- `String` - just passed in to `JOIN #{structure} `
- `Array` with values(same order):
  - [table representation](#tables)
  - `Hash`
    - `:on` - [conditions](#conditions)
    - `:option` - optional - contains `Symbol` or `String` of join type... rename to type?
- `Array` with combination of possible structures.  
```ruby
join: 'users u ON u.id = m.user_id'
join: ['users u ON u.id = m.user_id',
       'skills s ON u.id = s.user_id']
join: [[:user, :u], { on: 'rgl = 123' }]
# => 'JOIN users u ON rgl = 123'
join: [[[:user, :u], { option: :full, on: [:or, 'mrgl = 2', 'rgl = 22'] }],
       [:master, { on: ['z = 12', 'mrgl = 12'] }]]
# => 'FULL JOIN user u ON mrgl = 2 OR rgl = 22 JOIN master ON z = 12 AND mrgl = 12'
```  

#### Order
Possible structures:
- `String`, `Symbol` just insert it in `"ORDER BY #{structure} "`
- [SQL function](#sql-function)
- `Hash`
  - key - previsious possible structures.
  - value - options representation
    - `Symbol` - `:last || :first || :asc || :desc`
    - `String` - `'<' || '>'` or smthng else that passed in to `USING`
    - `Array` - with symbols inside
- `Array` - any possible structures  
```ruby
order: 'z.amount DESC' || :name
# => 'ORDER BY z.amount DESC ' || 'ORDER BY name '
order: [:name, [:_case ...], { amount: [:first, :desc] }]
# => 'ORDER BY name, CASE ..., amount DESC NULLS FIRST '
```  

#### With
```ruby
with: [:alias_name, { select: true, from: :users}]
with: [[:alias_name, { select: true, from: :users}],
       [:alias_name_2, { select: {u: [:name, :email]},
                        from: :rgl}]]
# => 'WITH alias_name (SELECT * FROM users ), alias_name_2 (...) '
# OR
with name: { select: true },
     another_name: { select: :mrgl }
# => 'WITH name AS (SELECT * ), another_name AS (SELECT mrgl ) '
```  

#### Union
```ruby
union: [{ select: true, from: [:o_list, [:_values, [1], :al, [:master]]] },
        { select: true, from: [:co_list, [:_values, [0, :FALSE, :TRUE, 0],
                                                    :al, [:rating, :rejected,
                                                          :payment, :master]]] }]
'SELECT ... UNION SELECT ...'
```  

#### SQL Functions
##### Params
Pass argument as params to adapter  
```ruby
[:_values, [:_params, 'mrgl', true, 'rgl'], :z, [:f_1, :f_2, :f_3]]
['(VALUES($1, $2, $3) AS z (f_1, f_2, f_3))', ['mrgl', true, 'rgl']]
```

##### Values
Second and third arguments are nesessary right now, but in furure i'll do them optional.
Arguments:
- array of values, can be nested
- `AS` name
- column names  
```ruby
[:_values, [{u: [:name, :phone]}, :role, [:_params, 'rgl']], :z, [:n, :p, :r, :m]]
# => '(VALUES(u.name, u.phone, role, $1) AS z (n, p, r, m))'
```
### Result representation
#### ::Row
Result row - allow accessing data by field name via method - `row.name # => "mrgl"` or get hash representation with `row.to_h`
Contains
- `values`
- `pg_result` - `::Result` instance

#### ::Result < ::Row
Data can be accessed like from row - it use first row, or you can iterate rows.  
Methods `each`, `each_with_index`, `first`, `last`, `map`, `count`, `present?` delegates to `rows`. `index` delegates to `fields`.  
For data representation as `Hash` or `Array` exists method `present`  
After initialize `PG::Result` cleared  
##### Contains
- `rows` - Array of `::Row`
- `fields` - Array of column/alias names of returned data
- `options`
##### Options
- `:types` - hash representing which column require additional parsing and which type
- `:presenter_options`

#### ::Presenter
Used in `result.present(options = {})` for data representation as `Hash` or `Array`. Options are merged with `result.options[:presenter_options]`  
Data will be presented as `Array` if `rows > 1` or `options[:array]` present.
##### Available options
- `array` - if querry returns only one row, but on client you await for array of data.
- `structure` - `Hash` with field as key and value as modifier. Modifier will rewrite field value in result. Modifier acts:
  - `Proc` - it will call proc with row as argument, and! then pass it to modifier_presentation again
  - `::Result` - it will call `modifier.present`
  - any else will be returned without changes
- `delete` - (will be soon) - Symbol, String or Array representing keys that must be deleted from result data.

## TODO:
Except this todo's there is a lot commented todo's inside project.-_-
- [x] Parse data like arrays, booleans, nil to SQL. (:_params function -\_-)
- [x] Relocate functions builder in to class, finally I found how it can be done nice=))
- [ ] Rename functions methods and do method_missing for them that will just pass arguments.
- [ ] should I bother with extra spaces?
- [ ] Insert
- [ ] Update
- [ ] Delete

### Tests
- [ ] Normal structure!!!!
- [ ] Constructor + Builder
- [ ] Result
- [ ] Request

### Meditate
- [ ] from
- [ ] join !!!
- [ ] where !!!!!! Supporting rails like syntax with hash?
- [ ] supporting another databases

## Contact
You can write me your suggestions for improving the syntax, wishes, things that you think are missing here.  
My [email](mailto:aeonax.liar@gmail.com), [Ruby On Rails slack](https://rubyonrails-link.slack.com/messages/D8W1WSRAP)
