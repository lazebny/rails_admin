module RailsAdmin
  class NavigationPresenter
    def initialize(view_context)
      # @controller = view_context.controller
      @view_context = view_context
      @config = ::RailsAdmin::Config
      @i18n = ::I18n
    end

    delegate :controller,
             :rails_admin,
             to: :@view_context

    def static_navigation?
      static_navigation_links.any?
    end

    def static_navigation_label
      @config.navigation_static_label || I18n.t('admin.misc.navigation_static_label')
    end

    def static_navigation_links
      @config.navigation_static_links
    end

    def main_navigation
      nodes_stack = @config.visible_models(controller: controller)
      node_model_names = nodes_stack.map(&:abstract_model_name)

      nodes_stack
        .group_by(&:navigation_label)
        .flat_map do |navigation_label, nodes|

        child_nodes = nodes.select do |n|
          # without parent or parent is unknown model
          n.parent.nil? || !node_model_names.include?(n.parent.to_s)
        end

        next if child_nodes.empty?

        [
          @view_context.render(
            partial: 'layouts/rails_admin/main_navigation/li_label',
            locals: { label: navigation_label || I18n.t('admin.misc.navigation') }
          ),
          *navigation(nodes_stack, child_nodes, 0)
        ]
      end.join.html_safe
    end

    private

    def navigation(nodes_stack, nodes, level)
      nodes.flat_map do |node|
        child_nodes = nodes_stack.select(&node.method(:parent_for?))
        [
          @view_context.render(
            partial: 'layouts/rails_admin/main_navigation/li_model',
            locals: { config_model: node, level: level }
          ),
          *navigation(nodes_stack, child_nodes, level + 1)
        ]
      end
    end
  end
end
