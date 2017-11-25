module RailsAdmin
  class ApplicationController < Config.parent_controller.constantize
    protect_from_forgery with: :exception

    before_action { instance_eval(&RailsAdmin::Config.authenticate_with) }
    before_action { instance_eval(&RailsAdmin::Config.authorize_with) }
    before_action { instance_eval(&RailsAdmin::Config.audit_with) }

    helper_method :_current_user, :_get_plugin_name

    attr_reader :authorization_adapter

    def _current_user
      instance_eval(&RailsAdmin::Config.current_user_method)
    end

    def method_missing(method_name, *args, &block)
      if view_context.respond_to?(method_name)
        ActiveSupport::Deprecation.warn(
          "Method '#{method_name}' in controller is deprecated " \
          "and will be removed in Rails Admin major release. " \
          "Please use 'view_context.#{method_name}'")
        view_context.send(method_name, *args, &block)
      else
        super
      end
    end

  private

    def _get_plugin_name
      @plugin_name_array ||=
        begin
          name = RailsAdmin.config.main_app_name
          Array(name.is_a?(Proc) ? instance_eval(&name) : name)
        end
    end

    def rails_admin_controller?
      true
    end
  end
end
