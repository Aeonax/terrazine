module Terrazine
  class Builder

    private

    def build_param(value)
      # no need for injections check - pg gem will check it
      @params << value
      "$#{@params.count}"
    end

    def wrap_result(sql)
      res = @params.count.positive? ? [sql, @params] : sql
      @params = []
      res
    end
  end
end
