module Terrazine
  class Config
    class << self
      def set(params)
        # another way?
        @@connection = params[:connection] if params[:connection]
      end

      def connection(conn = nil)
        @@connection ||= conn
        conn || @@connection
      end

      def connection!(conn = nil)
        connection(conn) || raise # TODO: error
      end
    end
  end
end
