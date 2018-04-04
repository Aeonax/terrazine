module Terrazine
  class Config
    class << self
      def set(params)
        # another way?
        @@connection = params[:connection] if params[:connection]
      end

      def connection(conn = nil)
        @@connection ||= conn
        c = conn || @@connection
        # Proc because of closing PG::Connection by rails on production -_-
        c.is_a?(Proc) ? c.call : c
      end

      def connection!(conn = nil)
        connection(conn) || raise # TODO: error
      end
    end
  end
end
