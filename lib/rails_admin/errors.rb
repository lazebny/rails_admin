module RailsAdmin
  module Errors
    ActionNotAllowed = Class.new(::StandardError)
    ModelNotFound = Class.new(::StandardError)
    ObjectNotFound = Class.new(::StandardError)

    class ActionAlreadyRegistred < StandardError
      def initialize(action)
        @action = action
      end

      def message
        "Action #{@action.custom_key} already exists. Please change its custom key."
      end
    end
  end
end
