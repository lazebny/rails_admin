module RailsAdmin
  class ApplicationController < Config.parent_controller.constantize
    protect_from_forgery with: :exception

    before_action { instance_eval &RailsAdmin::Config.authenticate_with }
    before_action { instance_eval &RailsAdmin::Config.authorize_with }
    before_action { instance_eval &RailsAdmin::Config.audit_with }
    before_action :get_app_presenter

    helper_method :_current_user

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

    def rails_admin_controller?
      true
    end

    def get_app_presenter
      @app_presenter ||= ::RailsAdmin::AppPresenter.new(view_context)
    end
  end
end
