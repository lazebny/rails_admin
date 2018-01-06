module RailsAdmin
  module Config
    module Actions
      class HistoryShow < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :authorization_key do
          :history
        end

        register_instance_option :member do
          true
        end

        register_instance_option :route_fragment do
          'history'
        end

        register_instance_option :controller do
          proc do
            @history = []
            @history = @auditing_adapter.listing_for_object(
              @abstract_model,
              @object,
              params[:query],
              params[:sort],
              params[:sort_reverse],
              params[:all],
              params[:page]
            ) unless @auditing_adapter.nil?

            render @action.template_name
          end
        end

        register_instance_option :template_name do
          :history
        end

        register_instance_option :link_icon do
          'icon-book'
        end
      end
    end
  end
end
