module RailsAdmin
  module Layouts
    module Navigation
      class SecondaryNavigationCell < BaseCell
        delegate(
          :_current_user,
          :content_tag,
          :link_to,
          :main_app,
          :rcell,
          :t,
          :url_for,
          :wording_for,
          to: :view_context
        )

        def initialize(*)
          super
          @user_cell = ::RailsAdmin::Layouts::Navigation::SecondaryNavigation::UserCell.build(
            view_context,
            _current_user
          )
        end

        def render_show
          content_tag(:ul, class: 'nav navbar-nav navbar-right root_links') do
            join_renders(
              *root_links,
              home_link,
              *user_links
            )
          end
        end

        private

        def root_links
          select_visible_actions(&:root).map do |action|
            content_tag(:li, class: "#{action.action_name}_root_link") do
              link_to(
                wording_for(:menu, action),
                url_for(
                  action: action.action_name,
                  controller: 'rails_admin/main'
                ),
                class: ('pjax' if action.pjax?)
              )
            end
          end
        end

        def home_link
          return unless main_app.respond_to?(:root_path)

          content_tag(:li) { link_to t('admin.home.name'), main_app.root_path }
        end

        def user_links
          return [] if _current_user.nil?

          [
            @user_cell[:edit_link],
            @user_cell[:logout_link]
          ]
        end
      end
    end
  end
end
