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
This was my first meeting with OOP... Now it's scary inside, but it can grow in shiny gem in future=)

#### Readiness
I done this gem for my own use. And I use it on our prod for constructing huge SQL SELECT queries and it works really well^\_^ BUT. Now it really unstable and some parts will be remade in future... So if you accidentally got lost and got on this page, then I advise you to use this gem only for informational purposes, or on your own risk=)

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
