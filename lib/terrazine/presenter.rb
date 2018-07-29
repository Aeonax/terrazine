module Terrazine
  # convinient for API presenter
  class Presenter
    # just wtf is going on here...
    class << self
      # TODO: delete fields
      def present(result, options)
        if options[:array] || result.count > 1
          return [] if result.count.zero?
          result.map { |i| present_row i, options[:structure] }
        else
          return nil if result.count.zero?
          present_row result, options[:structure]
        end
      end

      def present_row(row, structure)
        hash = row.to_h
        if structure.present?
          structure.each do |k, v|
            hash[k] = present_value(row, v)
          end
        end
        hash.compact
      end

      # TODO!!!
      def present_value(row, modifier)
        case modifier
        when Result
          modifier.present
        when Proc
          present_value row, modifier.call(row)
        else
          modifier
        end
      end
    end
  end
end
