require 'pg'
require 'pg_hstore'

module Terrazine
  # PG type map updater
  class TypeMap
    class << self
      def update(pg_result, types)
        # TODO! why it sometimes column_map?
        t_m = pg_result.type_map
        columns_map = t_m.is_a?(PG::TypeMapByColumn) ? t_m : t_m.build_column_map(pg_result)
        coders = columns_map.coders.dup
        types.each do |name, type|
          coders[pg_result.fnumber(name.to_s)] = fetch_text_decoder type
        end
        pg_result.type_map = PG::TypeMapByColumn.new coders
      end

      def fetch_text_decoder(type)
        # decoder inside decoder
        # as example array of arrays with integers - type == [:array, :array, :integer]
        if type.is_a?(Array)
          decoder = new_text_decoder type.shift
          assign_elements_type type, decoder
        else
          new_text_decoder type
        end
      end

      def assign_elements_type(types, parent)
        parent.elements_type = if types.count == 1
                                 select_text_decoder(types.shift).new
                               else
                                 type = types.shift
                                 assign_elements_type(types, select_text_decoder(type))
                               end
        parent
      end

      def new_text_decoder(type)
        select_text_decoder(type).new
      end

      def select_text_decoder(type)
        decoder = { array: PG::TextDecoder::Array,
                    float: PG::TextDecoder::Float,
                    boolaen: PG::TextDecoder::Boolean,
                    integer: PG::TextDecoder::Integer,
                    date: PG::TextDecoder::TimestampWithoutTimeZone,
                    hstore: Hstore,
                    json: PG::TextDecoder::JSON }[type]
        raise "Undefined decoder #{type}" unless decoder
        decoder
      end
    end
  end

  class Hstore < PG::SimpleDecoder
    def decode(string, _tuple = nil, _field = nil)
      PgHstore.load(string, true) if string.is_a? String
    end
  end
end
