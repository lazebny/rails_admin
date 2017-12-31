module RailsAdmin
  module Index
    class FiltersCell < BaseCell
      delegate(
        :authorized?,
        :capitalize_first_letter,
        :content_tag,
        :link_to,
        :options_for_select,
        :params,
        :t,
        :wording_for,
        to: :view_context
      )

      delegate(
        :export_path,
        :index_path,
        to: :rails_admin
      )

      def initialize(*)
        super

        @icon_cell = ::RailsAdmin::IconCell.build(view_context)
      end

      #
      # delegate :index_path,
      #          to: :rails_admin
      def render_show(with_filters: false)
        view_context.render(
          partial: 'rails_admin/main/index/query',
          locals: {
            export_action: call(:export_action),
            filters_box_style: ordered_filters.any? ? 'display:block' : 'display:none',
            form_path: form_path,
            query: params[:query],
            refresh_icon: refresh_icon,
          }
        )
      end

      def render_filters_js
        return if ordered_filters.empty?

        str = ordered_filters.map do |duplet|
          options = {index: duplet[0]}
          filter_for_field = duplet[1]
          filter_name = filter_for_field.keys.first
          filter_hash = filter_for_field.values.first
          field = filterable_fields.find { |f| f.name == filter_name.to_sym }

          if field.nil?
            raise "#{filter_name} is not currently filterable; " \
                   "filterable fields are #{filterable_fields.map(&:name).join(', ')}"
          end

          case field.type
          when :enum
            enum = field.with(object: abstract_model.model.new).enum
            options[:select_options] = options_for_select(enum, filter_hash['v'])
          when :date, :datetime, :time
            options[:datetimepicker_format] = field.parser.to_momentjs
          end

          options[:label] = field.label
          options[:name]  = field.name
          options[:type]  = field.type
          options[:value] = filter_hash['v']
          options[:label] = field.label
          options[:operator] = filter_hash['o']

          "$.filters.append(#{options.to_json});"
        end.join("\n")

        "jQuery(function($) { \n#{str}\n });"
      end

      def render_filters
        return if filterable_fields.empty?

        items = filterable_fields.map { |field| call(:filter, field)}

        view_context.render(
          partial: 'rails_admin/main/index/dropdown',
          locals: {
            id: 'filters',
            items: items,
            title:  t('admin.misc.add_filter')
          }
        )
      end

      def render_bulk_menu
        return unless model_config.list.checkboxes?

        bulk_actions = select_visible_actions(object: nil, &:bulkable?)

        return if bulk_actions.empty?

        items = bulk_actions.map do |action|
          onclick = [
            "jQuery('#bulk_action').val('#{action.action_name}')",
            "jQuery('#bulk_form').submit()",
            "return false;"
          ]
          content_tag :li do
            link_to(wording_for(:bulk_link, action), '#', onclick: onclick.join(";\n"))
          end
        end

        view_context.render(
          partial: 'rails_admin/main/index/dropdown',
          locals: {
            id: nil,
            items: items,
            title: t('admin.misc.bulk_menu_title')
          }
        )
      end

      private

      def render_filter(field)
        field_options =
          case field.type
          when :enum
            options_for_select(field.with(object: abstract_model.model.new).enum)
          else
           ''
          end.html_safe

        date_format = field.try(:parser) && field.parser.to_momentjs

        content_tag(:li) do
          link_to(
            capitalize_first_letter(field.label),
            '#',
            :"data-field-label" => field.label,
            :"data-field-name" => field.name,
            :"data-field-options" => field_options,
            :"data-field-type" => field.type,
            :"data-field-value" => "",
            :"data-field-datetimepicker-format" => date_format
          )
        end
      end

      def render_export_action
        export_action = find_visible_action(:export, object: nil)
        export_params = params.permit(
          :f,
          :query,
          :scope,
          :sort,
          :sort_revers,
        )

        return if export_action.nil?
        return unless authorized?(export_action.authorization_key, abstract_model)

        content_tag(:span, style: 'float:right') do
          link_to wording_for(:link, export_action),
                  export_path(export_params),
                  class: 'btn btn-info'
        end
      end

      def form_path
        index_params = params.permit(
          :scope,
          :set,
          :sort,
          :sort_reverse,
        )
        index_path(index_params)
      end

      def refresh_icon
        @icon_cell[:show, 'icon-white icon-refresh', t('admin.misc.refresh')]
      end

      def filterable_fields
        @filterable_fields ||= model_config.list.fields.select(&:filterable?)
      end

      def ordered_filters
        @ordered_filters ||=
          begin
            index = 0
            filters = params[:f].try(:permit!).try(:to_h) || model_config.list.filters
            filters.inject({}) do |memo, filter|
              field_name = filter.is_a?(Array) ? filter.first : filter
              filter_hash = filter.is_a?(Array) ? filter.last : {(index += 1) => {'v' => ''}}
              filter_hash.each do |index, filter_hash|
                if filter_hash['disabled'].blank?
                  memo[index] = {field_name => filter_hash}
                else
                  params[:f].delete(field_name)
                end
              end
            memo
          end.to_a.sort_by(&:first)
        end
      end
    end
  end
end
