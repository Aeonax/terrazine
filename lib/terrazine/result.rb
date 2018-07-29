require 'forwardable'

module Terrazine
  # respresent result row
  class Row
    extend Forwardable
    # attr_reader :pg_result, :values
    def initialize(pg_result, values)
      # @pg_result = pg_result
      # @values = values
      # Hiding from console a lot of data lines-_- ... another method?
      define_singleton_method(:pg_result) { pg_result }
      define_singleton_method(:values) { values }
    end

    def respond_to_missing?(method_name, include_all = true)
      index(method_name.to_s) || super
    end

    def method_missing(method_name, *_)
      indx = index(method_name.to_s)
      indx || super
      return unless values
      values[indx]
    end

    def to_h
      return {} unless values.present?
      pg_result.fields.zip(values).to_h
    end

    def_delegator :pg_result, :index
  end

  # inheritance from row for delegation methods to first row... may be method missing?
  class Result < Row
    attr_reader :rows, :fields, :options

    # TODO: as arguments keys, values and options? Future support of another db?
    # arguments - PG::Result instance and hash of options
    def initialize(result, options)
      # how another db parsing data?
      TypeMap.update(result, options[:types]) if options[:types]

      @options = options
      @fields = result.fields
      @rows = []
      result.each_row { |i| @rows << Row.new(self, i) }
      result.clear # they advise to clear it, but maybe better to use it until presenter?
    end

    def present(o = {})
      options = @options[:presenter_options] ? o.merge(@options[:presenter_options]) : o
      Presenter.present(self, options)
    end

    # ResultRow inheritance support
    def values
      first&.values
    end

    def pg_result
      self
    end

    def_delegators :@rows, :each, :each_with_index, :first, :last,
                           :map, :count, :present?, :empty?
    def_delegator :@fields, :index
  end
end
