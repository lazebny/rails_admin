module RailsAdmin
  class BaseCell
    delegate(
      :controller,
      :main_app,
      :rails_admin,
      to: :view_context
    )

    delegate(
      :abstract_model,
      to: :model_config
    )

    def self.build(view_context, model = nil, options = {})
      new(view_context, model, options)
    end

    def initialize(view_context, model = nil, options = {})
      @model = model
      @options = options
      @view_context = view_context
      @abstract_model = ::RailsAdmin::AbstractModel
      @actions = ::RailsAdmin::Config::Actions
      @config = ::RailsAdmin::Config
    end

    def call(view_name, *args, &block)
      send("render_#{view_name}", *args, &block)
        .to_s
        .html_safe
    end

    alias [] call

    private

    attr_reader :model, :options, :view_context

    def join_renders(*renders)
      renders
        .compact
        .join
        .html_safe
    end

    def model_config
      return model.config if model.is_a?(@abstract_model)

      @config.model(model)
    end

    def find_visible_action(action_name, **bindings)
      @actions.find_visible(action_name, with_default_bindings(bindings))
    end

    def select_visible_actions(**bindings, &filter)
      @actions.select_visible(with_default_bindings(bindings), &filter)
    end

    def with_default_bindings(bindings)
      lbindings = bindings.dup
      lbindings[:abstract_model] = abstract_model unless bindings.key?(:abstract_model)
      lbindings[:controller] = controller unless bindings.key?(:controller)
      lbindings[:object] = model unless bindings.key?(:object)
      lbindings
    end
  end
end
