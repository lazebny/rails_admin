module RailsAdmin
  class AppPresenter
    def initialize(controller, view_context)
      @controller = controller
      @view_context = view_context
      @config = ::RailsAdmin.config
    end

    delegate :edit_user_link,
             :logout_method,
             :logout_path,
             to: :user_presenter

    def plugin_full_name
      [plugin_first_name, plugin_last_name].join(' ')
    end

    def plugin_first_name
      plugin_name[0] || 'Rails' # FIXME: to use I18n.
    end

    def plugin_last_name
      plugin_name[1] || 'Admin' # FIXME: to use I18n.
    end

    private

    # Application name for header.
    #
    # Returns:
    #   Array[first_name, last_name]
    #
    def plugin_name
      @plugin_name ||=
        case @config.main_app_name
        when ::Array
          @config.main_app_name
        when ::Proc
          Array(@controller.instance_eval(&@config.main_app_name))
        else
          Array(@config.main_app_name)
        end
    end

    def user_presenter
      @user_presenter ||= RailsAdmin::UserPresenter.new(current_user, @controller, @view_context)
    end

    def current_user
      @controller._current_user
    end
  end
end
