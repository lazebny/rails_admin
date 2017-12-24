require 'rails_admin/support/i18n'

module RailsAdmin
  module ApplicationHelper
    include RailsAdmin::Support::I18n

    def capitalize_first_letter(wording)
      return nil unless wording.present? && wording.is_a?(String)

      wording = wording.dup
      wording[0] = wording[0].mb_chars.capitalize.to_s
      wording
    end

    def authorized?(action_name, abstract_model = nil, object = nil)
      object = nil if object.try :new_record?
      action(action_name, abstract_model, object).try(:authorized?)
    end

    def current_action?(action, abstract_model = @abstract_model, object = @object)
      @action.custom_key == action.custom_key &&
        abstract_model.try(:to_param) == @abstract_model.try(:to_param) &&
        (@object.try(:persisted?) ? @object.id == object.try(:id) : !object.try(:persisted?))
    end

    def action(key, abstract_model = nil, object = nil)
      bindings = {
        controller: controller,
        abstract_model: abstract_model,
        object: object
      }
      RailsAdmin::Config::Actions.find_visible(key, bindings)
    end

    def actions(scope = nil, abstract_model = nil, object = nil)
      bindings = {
        controller: controller,
        abstract_model: abstract_model,
        object: object,
      }

      if scope.nil? || scope == :all
        RailsAdmin::Config::Actions.select_visible(bindings)
      else
        RailsAdmin::Config::Actions.select_visible(bindings, &:"#{scope}?")
      end
    end

    def wording_for(label, action = @action, abstract_model = @abstract_model, object = @object)
      model_config = abstract_model.try(:config)
      object = abstract_model && object.is_a?(abstract_model.model) ? object : nil
      action = RailsAdmin::Config::Actions.find(action.to_sym) if action.is_a?(Symbol) || action.is_a?(String)

      capitalize_first_letter I18n.t(
        "admin.actions.#{action.i18n_key}.#{label}",
        model_label: model_config && model_config.label,
        model_label_plural: model_config && model_config.label_plural,
        object_label: model_config && object.try(model_config.object_label_method),
      )
    end

    def main_navigation
      # @app_presenter.main_navigation

      ::RailsAdmin::NavigationPresenter.new(self).main_navigation
    end

    def breadcrumb(action = @action, _acc = [])
      begin
        (parent_actions ||= []) << action
      end while action.breadcrumb_parent && (action = action(*action.breadcrumb_parent)) # rubocop:disable Loop

      content_tag(:ol, class: 'breadcrumb') do
        parent_actions.collect do |a|
          am = a.send(:eval, 'bindings[:abstract_model]')
          o = a.send(:eval, 'bindings[:object]')
          content_tag(:li, class: current_action?(a, am, o) && 'active') do
            crumb = begin
              if !current_action?(a, am, o)
                if a.http_methods.include?(:get)
                  link_to rails_admin.url_for(action: a.action_name, controller: 'rails_admin/main', model_name: am.try(:to_param), id: (o.try(:persisted?) && o.try(:id) || nil)), class: 'pjax' do
                    wording_for(:breadcrumb, a, am, o)
                  end
                else
                  content_tag(:span, wording_for(:breadcrumb, a, am, o))
                end
              else
                wording_for(:breadcrumb, a, am, o)
              end
            end
            crumb
          end
        end.reverse.join.html_safe
      end
    end

    # parent => :root, :collection, :member
    def menu_for(parent, abstract_model = nil, object = nil, only_icon = false) # perf matters here (no action view trickery)
      actions(parent, abstract_model, object)
        .select(&:http_method_get?)
        .map do |action|
        wording = wording_for(:menu, action)
        %(
          <li title="#{wording if only_icon}" rel="#{'tooltip' if only_icon}" class="icon #{action.key}_#{parent}_link #{'active' if current_action?(action)}">
            <a class="#{action.pjax? ? 'pjax' : ''}" href="#{rails_admin.url_for(action: action.action_name, controller: 'rails_admin/main', model_name: abstract_model.try(:to_param), id: (object.try(:persisted?) && object.try(:id) || nil))}">
              <i class="#{action.link_icon}"></i>
              <span#{only_icon ? " style='display:none'" : ''}>#{wording}</span>
            </a>
          </li>
        )
      end.join.html_safe
    end

    # FIXME: Deprecated
    def bulk_menu(abstract_model = @abstract_model)
      locals = {
        actions: actions(:bulkable, abstract_model)
      }
      render partial: 'rails_admin/main/index/bulk_menu', locals: locals
    end

    def flash_alert_class(flash_key)
      case flash_key.to_s
      when 'error'  then 'alert-danger'
      when 'alert'  then 'alert-warning'
      when 'notice' then 'alert-info'
      else "alert-#{flash_key}"
      end
    end
  end
end
