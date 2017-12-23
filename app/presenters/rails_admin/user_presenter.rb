module RailsAdmin
  class UserPresenter
    def initialize(user, controller, view_context)
      @user = user
      @view_context = view_context
      @controller = controller
      @actions = ::RailsAdmin::Config::Actions
      @config = ::RailsAdmin::Config
      @md5 = Digest::MD5
    end

    delegate :main_app,
             :rails_admin,
             to: :@view_context

    def logout_path
      if defined?(Devise)
        scope = Devise::Mapping.find_scope!(@user)
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
      return nil unless @user.respond_to?(:email)

      abstract_model = @config.model(@user).abstract_model
      return nil unless abstract_model

      edit_action = @actions.find_visible(:edit,
                                           abstract_model: abstract_model,
                                           controller: @controller,
                                           object: @user)
      return nil unless edit_action && edit_action.authorized?

      options = {
        action: edit_action.action_name,
        controller: 'rails_admin/main',
        id: @user.id,
        model_name: abstract_model.to_param
      }

      @view_context.link_to rails_admin.url_for(options) do
        html = []
        if @config.show_gravatar && @user.email.present?
          html << @view_context.image_tag(
            gravatar_url(email: @user.email, ssl: @controller.request.ssl?),
            alt: ''
          )
        end
        html << @view_context.content_tag(:span, @user.email)
        html
          .join
          .html_safe
      end
    end

    private

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
