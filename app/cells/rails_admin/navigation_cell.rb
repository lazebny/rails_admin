module RailsAdmin
  class NavigationCell < BaseCell
    delegate(
      :capitalize_first_letter,
      :content_tag,
      :link_to,
      :t,
      to: :view_context
    )

    delegate(
      :index_path,
      to: :rails_admin
    )

    def initialize(*)
      super

      @icon_cell = ::RailsAdmin::IconCell.build(view_context)
    end

    def render_static_navigation
      links = @config.navigation_static_links

      return if links.empty?

      join_renders(
        render_header(@config.navigation_static_label || t('admin.misc.navigation_static_label')),
        *(links.map do |title, url|
           content_tag(:li, link_to(title.to_s, url, target: '_blank'))
          end)
      )
    end

    def render_main_navigation
      nodes_stack = @config.visible_models(controller: controller)
      node_model_names = nodes_stack.map(&:abstract_model_name)

      join_renders(
        *nodes_stack
          .group_by(&:navigation_label)
          .flat_map do |navigation_label, nodes|

          child_nodes = nodes.select do |n|
            # without parent or parent is unknown model
            n.parent.nil? || !node_model_names.include?(n.parent.to_s)
          end

          next if child_nodes.empty?

          [
            render_header(navigation_label || t('admin.misc.navigation')),
            *navigation(nodes_stack, child_nodes, 0)
          ]
        end
      )
    end

    private

    def render_header(text)
      content_tag(:li, capitalize_first_letter(text), class: 'dropdown-header')
    end

    def navigation(nodes_stack, nodes, level)
      nodes.flat_map do |node|
        child_nodes = nodes_stack.select(&node.method(:parent_for?))
        [
          render_node(node, level),
          *navigation(nodes_stack, child_nodes, level + 1)
        ]
      end
    end

    def render_node(node, level)
      content_tag(:li, data: { model: node.abstract_model.to_param }) do
        url = index_path(model_name: node.abstract_model.to_param)
        classes = ['pjax']
        classes << "nav-level-#{level}" if level > 0

        link_to(
          @icon_cell[:show, node.navigation_icon, node.label_plural],
          url,
          class: classes.join(' ')
        ).html_safe
      end
    end
  end
end
