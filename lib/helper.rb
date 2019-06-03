# frozen_string_literal: true

# Really bad practice as for me, but...
class Array
  unless [].respond_to?(:second)
    def second
      self[1]
    end
  end
end

class Hash
  unless {}.respond_to?(:except)
    def except(*keys)
      return self if keys.nil?
      select { |k, _v| !keys.include?(k) }
    end
  end
end
