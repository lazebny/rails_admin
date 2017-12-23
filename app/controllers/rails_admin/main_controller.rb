module RailsAdmin
  class MainController < RailsAdmin::ApplicationController
    layout :get_layout

    before_action :get_app_presenter
    before_action :get_model, except: RailsAdmin::Config::Actions.select(&:root?).map(&:action_name)
    before_action :get_object, only: RailsAdmin::Config::Actions.select(&:member?).map(&:action_name)
    before_action :check_for_cancel

    attr_reader :object,
                :model_config,
                :abstract_model

    # EXCEPTION HANDLERS ------------------------------------------------------

    rescue_from RailsAdmin::Errors::ObjectNotFound do
      flash[:error] = I18n.t('admin.flash.object_not_found', model: @model_name, id: params[:id])
      params[:action] = 'index'
      @status_code = :not_found
      index
    end

    rescue_from RailsAdmin::Errors::ModelNotFound do
      flash[:error] = I18n.t('admin.flash.model_not_found', model: @model_name)
      params[:action] = 'dashboard'
      @status_code = :not_found
      dashboard
    end

    # ACTIONS -----------------------------------------------------------------

    RailsAdmin::Config::Actions.select.map(&:action_name).each do |action_name|
      define_method(action_name) do
        action = RailsAdmin::Config::Actions.find(action_name)
        unless @authorization_adapter.nil?
          @authorization_adapter.authorize(action.authorization_key, @abstract_model, @object)
        end
        @action = action.with(controller: self,
                              abstract_model: @abstract_model,
                              object: @object)
        raise(RailsAdmin::Errors::ActionNotAllowed) unless @action.enabled?
        @page_name = view_context.wording_for(:title)
        instance_eval &@action.controller
      end
    end

    def bulk_action
      return unless RailsAdmin::Config::Actions
                    .select_visible(controller: self, abstract_model: @abstract_model, &:bulkable?)
                    .collect(&:route_fragment)
                    .include?(params[:bulk_action])

      public_send(params[:bulk_action])
    end

    # OTHER -------------------------------------------------------------------

    def list_entries(model_config = @model_config,
                     auth_scope_key = :index,
                     additional_scope = get_association_scope_from_params,
                     pagination = !(params[:associated_collection] \
                                    || params[:all] \
                                    || params[:bulk_ids]))
      scope = model_config.abstract_model.scoped
      if auth_scope = @authorization_adapter \
                   && @authorization_adapter.query(auth_scope_key, model_config.abstract_model)
        scope = scope.merge(auth_scope)
      end
      scope = scope.instance_eval(&additional_scope) if additional_scope
      ::RailsAdmin::Config::Commands::GetList.new.call(params, model_config, scope, pagination)
    end

  private

    def get_model
      @model_name = RailsAdmin::AbstractModel.model_name_from_param(params[:model_name])

      @abstract_model = RailsAdmin::AbstractModel.new(@model_name)
      raise RailsAdmin::Errors::ModelNotFound if @abstract_model.nil?

      @model_config = @abstract_model.config
      raise RailsAdmin::Errors::ModelNotFound if @model_config.excluded?

      @properties = @abstract_model.properties
    end

    def get_object
      @object = @abstract_model.get(params[:id])
      raise RailsAdmin::Errors::ObjectNotFound if @object.nil?
    end

    def get_layout
      "rails_admin/#{request.headers['X-PJAX'] ? 'pjax' : 'application'}"
    end

    def back_or_index
      params[:return_to].presence \
      && params[:return_to].include?(request.host) \
      && (params[:return_to] != request.fullpath) ? params[:return_to] : index_path
    end

    def to_model_name(param)
      param.split('~').collect(&:camelize).join('::')
    end

    def redirect_to_on_success
      notice = I18n.t('admin.flash.successful',
                      name: @model_config.label,
                      action: I18n.t("admin.actions.#{@action.key}.done"))

      if params[:_add_another]
        redirect_to new_path(return_to: params[:return_to]),
                    flash: {success: notice}
      elsif params[:_add_edit]
        redirect_to edit_path(id: @object.id, return_to: params[:return_to]),
                    flash: {success: notice}
      else
        redirect_to back_or_index, flash: {success: notice}
      end
    end

    # TODO: Make sanitize explicit
    def sanitize_params_for!(action,
                             model_config = @model_config,
                             target_params = params[@abstract_model.param_key])
      bindings = {
        controller: self,
        view: view_context,
        object: @object
      }
      ::RailsAdmin::Support::SanitizeParams.new
        .call(action, model_config, target_params, bindings)
    end

    def handle_save_error(whereto = :new)
      message =
        I18n.t('admin.flash.error',
               name: @model_config.label,
               action: I18n.t("admin.actions.#{@action.key}.done")) \
              + %(<br>- #{@object.errors.full_messages.join('<br>- ')})

      flash.now[:error] = message.html_safe

      respond_to do |format|
        format.html { render whereto, status: :not_acceptable }
        format.js   { render whereto, layout: false, status: :not_acceptable }
      end
    end

    def check_for_cancel
      return unless params[:_continue] || (params[:bulk_action] && !params[:bulk_ids])
      redirect_to(back_or_index, notice: I18n.t('admin.flash.noaction'))
    end

    def get_association_scope_from_params
      return nil unless params[:associated_collection].present?
      source_abstract_model = RailsAdmin::AbstractModel.from_param(params[:source_abstract_model])
      source_model_config = source_abstract_model.config
      source_object = source_abstract_model.get(params[:source_object_id])
      action = params[:current_action].in?(%w(create update)) ? params[:current_action] : 'edit'
      @association = source_model_config
        .send(action)
        .fields
        .detect { |f| f.name == params[:associated_collection].to_sym }
        .with(controller: self, object: source_object)
      @association.associated_collection_scope
    end
  end
end
