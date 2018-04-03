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
```ruby
# file config/application.rb
module Name
  class Application < Rails::Application
  # ....
    config.after_initialize do
      Terrazine.config connection: ActiveRecord::Base.connection.raw_connection
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

#### Select
Accepts 
- `String` || `Symbol`
- `Hash` represents column alias - 'AS' (if key begins from `_`) OR table alias that will join to the values table prefix OR another data structure(present keyword `:select`).
- Another `Constructor` or `Hash` representing data structure
- `Array` can contain all of the above structures OR in case of first symbol/string begins from `_` it will represent SQL function  
```ruby
constructor.select "name, email"
constructor.select :birthdate
constructor.select m: [:common_rating, :work_rating, { _master_id: :id }]
constructor.select { _missed_calls_count: { select: [:_count, [:_nullif, :connected, :true]],
                                           from: [:calls, :c],
                                           where: ['c.client_id = u.id',
                                                   ['direction = ?', 0]]} }
constructor.structure
# => { select: ['name, email', :birthdate,
#               { m: [:common_rating, :work_rating, { _master_id: :id }] },
#               { _missed_calls_count: { select: [:_count, [:_nullif, :connected, :true]],
#                                        from: [:calls, :c],
#                                        where: ['c.client_id = u.id',
#                                                ['direction = ?', 0]]} }] }

constructor.build_sql
# => ['SELECT name, email, birthdate, m.common_rating, m.work_rating, m.id AS master_id,
#             (SELECT COUNT(NULLIF(connected, TRUE))
#              FROM calls c
#              WHERE c.client_id = u.id AND direction = $1) AS missed_calls_count',
#     0]
```

#### From
Accepts
- `String` || `Symbol`
- `Array` can contains table_name and table_alias OR `VALUES` OR both  
```ruby
from 'table_name table_alias' || :table_name
from [:table_name, :table_alias]
from [[:table_name, :table_alias], [:_values, [1, 2], :values_name, [*values_column_names]]]
from [:mrgl, [:_values, [1, 2], :rgl, [:zgl, :gl]]]
```
I do not like the `from` syntax, but how it can be made more convenient...?

#### Join
Accpets
- `String`
- `Array`:
First element same as `from` first element - table name or `Array` of table_name and table_alias, then `Hash` with keys:
  - on - conditions(description will be bellow)
  - options - optional contains `Symbol` or `String` of join type... rename to type?  

`Array` can be nested  
```ruby
join 'users u ON u.id = m.user_id'
join ['users u ON u.id = m.user_id',
      'skills s ON u.id = s.user_id']
join [[:user, :u], { on: 'rgl = 123' }]
join [[[:user, :u], { option: :full, on: [:or, 'mrgl = 2', 'rgl = 22'] }],
      [:master, { on: ['z = 12', 'mrgl = 12'] }]]
```

#### Conditions
Current conditions implementation is sux... -_- Soon i'll change it.  
Now it accepts `String` or `Array`.  
First element of array is `Symbol` representation of join condition - `:or || :and` or by default `:and`.  
```ruby
conditions 'mrgl = 12'
conditions ['z = 12', 'mrgl = 12']
conditions ['NOT z = 13', [:or, 'mrgl = 2', 'rgl = 22']]
conditions [:or, ['NOT z = 13', [:or, 'mrgl = 2', 'rgl = 22']],
                 [:or, 'rgl = 12', 'zgl = lol']]
conditions [['NOT z = 13',
            [:or, 'mrgl = 2', 'rgl = 22']],
            [:or, 'rgl = 12', 'zgl = lol']]
# => 'NOT z = 13 AND (mrgl = 2 OR rgl = 22) AND (rgl = 12 OR zgl = lol)'
```

#### With
```ruby
with [:alias_name, { select: true, from: :users}]
with [[:alias_name, { select: true, from: :users}],
      [:alias_name_2, { select: {u: [:name, :email]},
                        from: :rgl}]]
```

#### Union
```ruby
union: [{ select: true, from: [:o_list, [:_values, [1], :al, [:master]]] },
        { select: true, from: [:co_list, [:_values, [0, :FALSE, :TRUE, 0],
                                                    :al, [:rating, :rejected,
                                                          :payment, :master]]] }]
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
Used in `result.present(options = {})` - it represents data as `Hash` or `Array`. Options are merged with `result.options[:presenter_options]`  
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
- [ ] Parse data like arrays, booleans, nil to SQL
- [ ] Relocate functions builder in to class, finally I found how it can be done nice=))
- [ ] meditate about structure supporting another databases(now supports only postgress)
- [ ] should I bother with extra spaces?

### Tests
- [ ] Constructor + Builder
- [ ] Result
- [ ] Request

### Meditate on a better data structure for
- [ ] from
- [ ] join !!!
- [ ] where !!!!!! Support for rails like syntax with hash?  

## Contact
You can write me your suggestions for improving the syntax, wishes, things that you think are missing here.  
My [email](mailto:aeonax.liar@gmail.com), [Ruby On Rails slack](https://rubyonrails-link.slack.com/messages/D8W1WSRAP)
