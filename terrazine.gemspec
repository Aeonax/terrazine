$LOAD_PATH.push File.expand_path("../lib", __FILE__)

require 'version'

Gem::Specification.new do |spec|
  spec.name          = 'terrazine'
  spec.version       = Terrazine::VERSION
  spec.authors       = ['Aeonax']
  spec.email         = ['aeonax.liar@gmail.com']

  spec.summary       = %q(Terrazine is a parser of data structures in to SQL)
  spec.description   = %q(You can take a look at {github}[https://github.com/Aeonax/terrazine])
  spec.homepage      = 'https://github.com/Aeonax/terrazine'
  spec.license       = 'MIT'

  spec.files            = `git ls-files`.split("\n")
  spec.test_files       = `git ls-files -- {spec,features}/*`.split("\n")
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.add_dependency 'pg_hstore'
end
