class Multimethods
  def initialize
    @methods = {}
    @mapper = {}
    @index = 0
  end

  def add_method(value, &method)
    @index += 1
    method_name = @index
    @methods[method_name] = method
    if value.is_a?(Array)
      # how blocks storing? mapper really needed? or i can dublicate same values?
      value.map { |val| @mapper[val] = method_name }
    else
      @mapper[value] = method_name
    end
  end

  def assign_default(&method)
    @methods[:default] = method
  end

  def fetch_method(data)
    key = @mapper[data.class] || :default
    @methods[key]
  end

  def perform(data, *args)
    meth = fetch_method(data)
    meth[data, *args] if meth
  end
end

# multi = Multimethods.new
# multi.add_method(Array) do |arr|
#   puts arr.join(' azaz ')
# end

# multi.add_method(Hash) do |hs|
#   multi.perform(hs.values)
# end

# multi.perform([:mrgl, :rgl])
# # => mrgl azaz rgl
# multi.perform(name: 'Aeonax', role: 'Crab')
# # => Aeonax azaz Crab

# multi.add_method([Symbol, String]) do |s|
#   "#{s} is so nyashka"
# end
# multi.perform('Aeonax')
# # => "Aeonax is so nyashka"

# @multi = multi
# def some_method(data)
#   @multi.perform(data)
# end
