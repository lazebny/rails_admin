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

      def initialize(*)
        super
        @sortable_table = ::RailsAdmin::Shared::List::SortableTableCell.build(view_context)
      end

      def render_styles
        fieldset.select{ |p| p.column_width.present? }.flat_map do |field|
          th_style = [
            "width: #{field.column_width}px;",
            "min-width: #{field.column_width}px;"
          ]
          td_style = [
            "max-width: #{field.column_width}px;"
          ]
          [
            "#list th.#{field.css_class} {#{th_style.join(' ')}}",
            "#list td.#{field.css_class} {#{td_style.join(' ')}}"
          ]
        end.join("\n")
      end

      def render_thead
        content_tag(:tr) do
          join_renders(
            (content_tag(:th, class: 'shrink') do
              content_tag(:input, '', class: 'toggle', type: 'checkbox')
            end if checkboxes?),
            (content_tag(:th, '...', class: 'other left shrink') if left?),
            @sortable_table[:headers, fieldset],
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
            @sortable_table[:body_row, object, fieldset],
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

      def fieldset
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
            fieldset = visible_fields
            sets = []
            property_index = 0
            set_index = 0

            while property_index < fieldset.length
              current_set_width = 0
              loop do
                sets[set_index] ||= []
                sets[set_index] << fieldset[property_index]
                current_set_width += (fieldset[property_index].column_width || 120)
                property_index += 1
                break if current_set_width >= @config.total_columns_width \
                      || property_index >= fieldset.length
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
