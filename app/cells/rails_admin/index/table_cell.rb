module RailsAdmin
  module Index
    class TableCell < BaseCell
      delegate(
        :capitalize_first_letter,
        :check_box_tag,
        :content_tag,
        :link_to,
        :menu_for,
        :params,
        :strip_tags,
        to: :view_context
      )

      delegate(
        :index_path,
        to: :rails_admin
      )

      def render_styles
        properties.select{ |p| p.column_width.present? }.flat_map do |property|
          th_style = [
            "width: #{property.column_width}px;",
            "min-width: #{property.column_width}px;"
          ]
          td_style = [
            "max-width: #{property.column_width}px;"
          ]
          [
            "#list th.#{property.css_class} {#{th_style.join(' ')}}",
            "#list td.#{property.css_class} {#{td_style.join(' ')}}"
          ]
        end.join("\n")
      end

      def render_thead
        headers = properties.map do |property|
          if property.sortable
            sort_location = index_path(sort_params(property.name.to_s))
            sort_direction = sort_direction(property.name.to_s)
          else
            sort_location = nil
            sort_direction = nil
          end

          classes= [
           ("header pjax" if property.sortable),
           (sort_direction if property.sortable && sort_direction),
           property.css_class,
           property.type_css_class
          ]

          content_tag(
            :th,
             capitalize_first_letter(property.label),
             class: classes.compact.join(' '),
             :'data-href' => (sort_location if property.sortable),
             rel: 'tooltip',
             title: property.hint
            )
        end

        content_tag(:tr) do
          join_renders(
            (content_tag(:th, class: 'shrink') do
              content_tag(:input, '', class: 'toggle', type: 'checkbox')
            end if checkboxes?),
            (content_tag(:th, '...', class: 'other left shrink') if left?),
            headers.join("\n"),
            (content_tag(:th, '...', class: 'other right shrink') if right?),
            (content_tag(:th, '', class: 'last shrink') if checkboxes?)
          )
        end
      end

      def render_tbody(objects)
        join_renders(*objects.map(&method(:render_body_row)))
      end

      private

      def render_body_row(object)
        prop_tds = properties.map { |prop| prop.bind(:object, object) }.map do |lprop|
          value = lprop.pretty_value
          classes = [lprop.css_class, lprop.type_css_class]
          title = strip_tags(value.to_s)

          content_tag(:td, value, class: classes.join(' '), title: title)
        end

        classes = [
          "#{abstract_model.param_key}_row",
          model_config.list.with(object: object).row_css_class
        ]
        content_tag(:tr, class: classes.join(" ")) do
          join_renders(
            (content_tag(:td) { check_box_tag('bulk_ids[]', object.id, false) } if checkboxes?),
            (content_tag(:td, class: 'other left') do
              link_to('...', left_path, class: 'pjax')
            end if left?),
            *prop_tds,
            (content_tag(:td, class: 'other right') do
              link_to('...', right_path, class: 'pjax')
            end if right?),
            content_tag(:td, class: 'last links') do
              content_tag(:ul, class: 'inline list-inline') do
                menu_for :member, abstract_model, object, true
              end
            end
          )
        end
      end

      def left_path
        options = params.permit(
          :query,
          :f,
          :sort,
          :sort_reverse,
          :scope
        )
        options[:set] = set_index - 1 if set_index != 1

        index_path(options)
      end

      def right_path
        options = params.permit(
          :query,
          :f,
          :sort,
          :sort_reverse,
          :scope
        )
        options[:set] = set_index + 1

        index_path(options)
      end

      def checkboxes?
        model_config.list.checkboxes?
      end

      def sort_params(sort)
        lparams = {}
        lparams[:sort] = sort
        lparams[:sort_reverse] = "true" if active_sort?(sort) && !sort_reverse?
        params.permit(
          :query,
          :f,
          :scope,
          :set
        ).merge(lparams)
      end

      def sort_direction(sort)
        return unless active_sort?(sort)
        sort_reverse? ? 'headerSortUp' : 'headerSortDown'
      end

      def sort_reverse?
        params[:sort_reverse] == 'true'
      end

      def active_sort?(sort)
        params[:sort] == sort
      end

      def properties
        sets[set_index] || []
      end

      def left?
        set_index > 0 && sets[set_index - 1].present?
      end

      def right?
        sets[set_index + 1].present?
      end

      def set_index
        params[:set].to_i
      end

      def sets
        @sets ||=
          begin
            properties = visible_fields
            sets = []
            property_index = 0
            set_index = 0

            while property_index < properties.length
              current_set_width = 0
              loop do
                sets[set_index] ||= []
                sets[set_index] << properties[property_index]
                current_set_width += (properties[property_index].column_width || 120)
                property_index += 1
                break if current_set_width >= @config.total_columns_width \
                      || property_index >= properties.length
              end
              set_index += 1
            end
            sets
          end
      end

      def visible_fields
        bindings = {
          controller: controller,
          view: view_context,
          object: abstract_model.model.new
        }
        model_config
          .list
          .with(bindings)
          .visible_fields
      end
    end
  end
end
