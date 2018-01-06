module RailsAdmin
  module Config
    module Proxyable
      class Proxy < BasicObject
        attr_reader :bindings

        def initialize(object, bindings = {})
          @object = object
          @bindings = bindings
        end

        # Bind variables to be used by the configuration options
        def bind(key, value = nil)
          if key.is_a?(::Hash)
            @bindings = key
          else
            @bindings[key] = value
          end
          self
        end

        def method_missing(name, *args, &block)
          if respond_to_missing?(name)
            reset = @object.instance_variable_get('@bindings')
            begin
              @object.instance_variable_set('@bindings', @bindings)
              response = @object.__send__(name, *args, &block)
            ensure
              @object.instance_variable_set('@bindings', reset)
            end
            response
          else
            super(name, *args, &block)
          end
        end

        def respond_to_missing?(name)
          @object.respond_to?(name)
        end
      end
    end
  end
end
