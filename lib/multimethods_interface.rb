# frozen_string_literal: true

require_relative 'multimethods.rb'

module MultimethodsInterface
  def def_multi(*args, &method)
    distinction = if args.count > 1
                    method_name = args.first
                    args.second
                  else
                    method_name = :multimethod
                    args.first
                  end
    multimethod(method_name).add_method(distinction, &method)
  end

  def def_default_multi(method_name = :multimethod, &method)
    multimethod(method_name).assign_default(&method)
  end

  def multimethod(method_name)
    method = "@#{method_name}"
    return instance_variable_get(method) if instance_variable_defined?(method)

    initialize_multi(method_name, differ: :class)
  end

  # looks like shit...
  def initialize_multi(method_name = :multimethod, differ: :class, differ_by: false)
    m = instance_variable_set("@#{method_name}", Multimethods.new(differ))
    if differ_by
      define_method("#{method_name}_by") do |*args|
        method = m.fetch_method(args.first)
        next instance_exec(*args.drop(1), &method) if method
        instance_exec(args.first, *args.drop(1), &m.default_method)
      end
    else
      define_method(method_name) do |*args|
        method = m.fetch_method(args.first) || m.default_method
        instance_exec(*args, &method)
      end
    end
    m
  end
end
