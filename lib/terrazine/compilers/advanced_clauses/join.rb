# frozen_string_literal: true

module Terrazine
  module Compilers
    module AdvancedCompilers
      # relays on build_..., to_sql
      class Join < Compilers::Base
        def build(structure)
          case structure
          when Array
            # stopped supporting of structures like [[:users, :u], {...}]
            structure.map { |s| build(s) }.join
          when Hash
            structure.map { |k, v| parse_pair(k, v) }.join
          when String
            structure
          else
            raise # TODO!
          end
        end

        def parse_pair(key, value)
          case value
          when Hash # { u__name: 'Aeonax' } || { on: { u__.... }, type: ... }
            parse_hash_value(key, value)
          when Array # [:u, {...}] || [:_eq, :u__name, 'Aeonax']
            parse_array_value(key, value)
          else
            result(build_tables(key), to_sql(value))
          end
        end

        def parse_hash_value(key, value)
          condition = if value[:on]
                        option = value[:type]
                        build_conditions(value[:on])
                      else
                        build_conditions(value)
                      end
          result(build_tables(key), condition, option)
        end

        def parse_array_value(key, value)
          # requires to separate table alias and conditions... may be superstruction??
          if value.first.to_s.match?(/^_/) # check_alias(value)
            value[0] = value[0].sub(/^_/, '')
            result(build_tables(key), build_conditions(value))
          else
            result(build_tables([key, value[0]]), build_conditions(value[1..-1]))
          end
        end

        def result(from, condition, option = nil)
          "#{option.to_s.upcase + ' ' if option}JOIN #{from} ON #{condition}"
        end
      end
    end
  end
end
