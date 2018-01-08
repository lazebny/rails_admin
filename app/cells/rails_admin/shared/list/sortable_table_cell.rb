module RailsAdmin
  module Shared
    module List
      class SortableTableCell < BaseCell
        delegate(
          :capitalize_first_letter,
          :content_tag,
          :params,
          :strip_tags,
          to: :view_context
        )

        # sortable field interface:
        #   css_class
        #   hint
        #   label
        #   name
        #   sortable
        #   type_css_class

        def render_headers(fieldset)
          join_renders(
            *fieldset.map do |field|
              if field.sortable
                sort_location = current_path(header_url_params(field.name.to_s))
                sort_direction = sort_direction(field.name.to_s)
              else
                sort_location = nil
                sort_direction = nil
              end

              classes= [
               ("header pjax" if field.sortable),
               (sort_direction if field.sortable && sort_direction),
               field.css_class,
               field.type_css_class
              ]

              content_tag(
                :th,
                 capitalize_first_letter(field.label),
                 class: classes.compact.join(' '),
                 :'data-href' => (sort_location if field.sortable),
                 rel: 'tooltip',
                 title: field.hint
                )
            end
          )
        end

        def render_body(objects, fieldset)
          join_renders(*objects.map { |obj| render_body_row(obj, fieldset) })
        end

        def render_body_row(object, fieldset)
          fieldset = fieldset.map { |prop| prop.bind(:object, object) }

          join_renders(
            *fieldset.map do |prop|
              value = prop.pretty_value
              classes = [prop.css_class, prop.type_css_class]
              title = strip_tags(value.to_s)

              content_tag(:td, value, class: classes.join(' '), title: title)
            end
          )
        end

        private


        def current_path_options
          {
            action: edit_action.action_name,
            controller: 'rails_admin/main',
            id: model.id,
            model_name: abstract_model.to_param
          }
        end

        def active_sort?(sort)
          params[:sort] == sort
        end

        def sort_direction(sort)
          return unless active_sort?(sort)
          sort_reverse? ? 'headerSortUp' : 'headerSortDown'
        end

        def sort_reverse?
          params[:sort_reverse] == 'true'
        end

        def header_url_params(sort)
          lparams = {}
          lparams[:sort] = sort
          lparams[:sort_reverse] = "true" if active_sort?(sort) && !sort_reverse?
          params.permit(
            :f,
            :query,
            :scope,
            :set,
          ).merge(lparams)
           .symbolize_keys
        end
      end
    end
  end
end
