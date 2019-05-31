# Terrazin

## [Idea](https://github.com/Aeonax/terrazine/wiki)
Simple and comfortable, as possible, data structures parser in to SQL.  

#### [Data](https://github.com/Aeonax/terrazine/wiki/Data-Structures)
Describing sql with data structures like [honeysql](https://github.com/jkk/honeysql) or [ql](https://github.com/niquola/ql) in clojure.  

#### [Constructor](https://github.com/Aeonax/terrazine/wiki/Constructor)
Construct data structures inside Constructor instance.

#### [Result](https://github.com/Aeonax/terrazine/wiki/Result)
Get result and access any returned data rails like syntax.

#### Realization
This was my first meeting with OOP... Now it's scary inside, but there is [0.0.4](https://github.com/Aeonax/terrazine/pull/2) will be soon that will be not so scary=))

#### DB adapters
Now? supports only Postgresql.

#### Why?
I tried to find something that will help me to create complex SQL queries, but there was only `String` and `.erb`... They didn't respond to my requirements=( In my vision data structures, especially in combination with objects([Constructor](https://github.com/Aeonax/terrazine/wiki/Constructor)), more convinient way for representing complex SQL than `String` or `ORM`...  
As for me, the right question is why only now? Why so late? Or i still blind...

## Usage
#### Initialization
Add this line to the Gemfile  
```ruby
gem 'terrazine', '0.0.3'
```  
After server initialization set `Terrazine.config`. Now config accepts only `:connection` option. In the bright future will be added `:adapter` option support.  
In rails you can set config with [after_initialize](https://apidock.com/rails/Rails/Configuration/after_initialize) and it will looks like:  

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

## Updates:
#### 0.0.3
- Expand predicates syntax
- added support of multiple rows for `VALUES`
- `ORDER` structure
- `UPDATE` structure
- scary tests-\_-

## Contact
You can write me your suggestions for improving the syntax, wishes, things that you think are missing here.  
My [email](mailto:aeonax.liar@gmail.com), [Ruby On Rails slack](https://rubyonrails-link.slack.com/messages/D8W1WSRAP)
