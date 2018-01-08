module RailsAdmin
  module Layouts
    module Navigation
      module SecondaryNavigation
        class UserCell < BaseCell
          delegate(
            :content_tag,
            :image_tag,
            :link_to,
            :t,
            to: :view_context
          )

          def initialize(*)
            super
            @md5 = Digest::MD5
          end

          def render_edit_link
            link = edit_user_link

            return if link.nil?

            content_tag(:li, class: 'edit_user_root_link') { link }
          end

          def render_logout_link
            return if logout_path.nil?

            content_tag(:li) do
              link_to logout_path, method: logout_method do
                content_tag(:span, class: 'label label-danger') do
                  t('admin.misc.log_out')
                end
              end
            end
          end

          private

          def logout_path
            if defined?(Devise)
              scope = Devise::Mapping.find_scope!(model)
              main_app.public_send("destroy_#{scope}_session_path") rescue false
            elsif main_app.respond_to?(:logout_path)
              main_app.logout_path
            end
          end

          def logout_method
            return [Devise.sign_out_via].flatten.first if defined?(Devise)
            :delete
          end

          def edit_user_link
            return nil unless model.respond_to?(:email)
            return nil unless abstract_model

            edit_action = find_visible_action(:edit)

            return nil unless edit_action && edit_action.authorized?

            options = {
              action: edit_action.action_name,
              controller: 'rails_admin/main',
              id: model.id,
              model_name: abstract_model.to_param
            }

            link_to rails_admin.url_for(options) do
              join_renders(
                if @config.show_gravatar && model.email.present?
                  url = gravatar_url(email: model.email, ssl: controller.request.ssl?)
                  image_tag(url, alt: '')
                end,
                content_tag(:span, model.email)
              )
            end
          end

          def gravatar_url(email:, size: 30, ssl: false)
            protocol = ssl ? 'https://secure' : 'http://www'
            digest = @md5.hexdigest(email)
            options = {
              s: size
            }
            "#{protocol}.gravatar.com/avatar/#{digest}?#{options.to_query}"
          end
        end
      end
    end
  end
end
