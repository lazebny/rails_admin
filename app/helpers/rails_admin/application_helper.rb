require 'rails_admin/support/i18n'

module RailsAdmin
  module ApplicationHelper
    include RailsAdmin::Support::I18n

    def rcell(cell_class, *args)
      cell_class.build(self, *args)
    end

    # delegate :capitalize_first_letter,
    #          to: ::RailsAdmin::Support::TextHelper

    def capitalize_first_letter(text)
      return nil unless text.present? && text.is_a?(String)

      text
        .dup
        .tap { |t| t[0] = t[0].mb_chars.capitalize.to_s }
    end

    def authorized?(action_name, abstract_model = nil, object = nil)
      object = nil if object.try :new_record?
      action(action_name, abstract_model, object).try(:authorized?)
    end

    def current_action?(action,
                        global_action,
                        abstract_model = nil,
                        global_abstract_model = nil,
                        object = nil,
                        global_object = nil)
      # actions comparison
      return false unless global_action.custom_key == action.custom_key

      # abstract models comparison
      return false unless abstract_model.try(:to_param) == global_abstract_model.try(:to_param)

      # objects comparison
      if global_object.try(:persisted?)
        global_object.id == object.try(:id)
      else
        !object.try(:persisted?)
      end
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

    # parent => :root, :collection, :member
    def menu_for(parent, abstract_model = nil, object = nil, only_icon = false) # perf matters here (no action view trickery)
      actions(parent, abstract_model, object)
        .select(&:http_method_get?)
        .map do |action|
        wording = wording_for(:menu, action)
        %(
          <li title="#{wording if only_icon}" rel="#{'tooltip' if only_icon}" class="icon #{action.key}_#{parent}_link #{'active' if current_action?(action, @action)}">
            <a class="#{action.pjax? ? 'pjax' : ''}" href="#{rails_admin.url_for(action: action.action_name, controller: 'rails_admin/main', model_name: abstract_model.try(:to_param), id: (object.try(:persisted?) && object.try(:id) || nil))}">
              <i class="#{action.link_icon}"></i>
              <span#{only_icon ? " style='display:none'" : ''}>#{wording}</span>
            </a>
          </li>
        )
      end.join.html_safe
    end
  end
end
