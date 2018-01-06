module RailsAdmin
  class PluginCell < BaseCell
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
          Array(controller.instance_eval(&@config.main_app_name))
        else
          Array(@config.main_app_name)
        end
    end
  end
end
