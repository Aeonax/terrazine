require_relative '../lib/terrazine'

def structure(key)
  @constructor.structure[key]
end

def init_constructor(structure)
  Terrazine::Constructor.new(structure)
end
