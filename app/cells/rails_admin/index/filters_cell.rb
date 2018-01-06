module RailsAdmin
  module Index
    class FiltersCell < BaseCell
      delegate(
        :capitalize_first_letter,
        :content_tag,
        :link_to,
        :options_for_select,
        :params,
        :t,
        to: :view_context
      )

      def initialize(*)
        super
        @icon_cell = ::RailsAdmin::IconCell.build(view_context)
      end

      def render_placeholder
        style = ordered_filters.any? ? 'display:block' : 'display:none',
        join_renders(
          content_tag(:span, id: 'filters_box'),
          content_tag(:hr, class: 'filters_box', style: style)
        )
      end

      def render_reset_button
        content_tag(
          :button,
          @icon_cell[:remove_icon],
          id: 'remove_filter',
          class: 'btn btn-info',
          title: 'Reset filters'
        )
      end

      def render_dropdown
        return if filterable_fields.empty?

        items = filterable_fields.map { |field| call(:filter, field)}

        view_context.render(
          partial: 'rails_admin/main/shared/dropdown',
          locals: {
            id: 'filters',
            items: items,
            title:  t('admin.misc.add_filter')
          }
        )
      end

      def render_js
        return if ordered_filters.empty?

        str = ordered_filters.map do |duplet|
          options = { index: duplet[0] }
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
