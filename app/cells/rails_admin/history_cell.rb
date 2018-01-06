module RailsAdmin
  class HistoryCell < BaseCell
    delegate(
      :params,
      :form_tag,
      to: :view_context
    )

    def initialize(*)
      super
      @sortable_table = ::RailsAdmin::List::SortableTableCell.build(view_context)
    end

    def render_query_form(&block)
      form_tag(
        current_path,
        method: :get,
        class: "search pjax-form form-inline",
        &block
      )
    end

    def render_thead
      @sortable_table[:headers, fieldset]
    end

    def render_tbody(objects)
      @sortable_table[:body, objects, fieldset]
    end

    private

    def fieldset
      history_section.with(with_default_bindings).visible_fields
    end

    def history_section
      section = ::RailsAdmin::Config::Sections::List.new(abstract_model.config)
      section.init_fields(empty: true)
      section.instance_eval do
        field :created_at, :datetime do
          label I18n.t('admin.table_headers.created_at')
          sortable true
        end
        field :username do
          label I18n.t('admin.table_headers.username')
          sortable true
        end
        field :item do
          label I18n.t('admin.table_headers.item')
          pretty_value do
            abstract_model = bindings[:abstract_model]

            object = abstract_model.get(bindings[:object].item)
            if object.nil?
              "#{abstract_model.config.label} ##{object.item}"
            else
              label = object.public_send(abstract_model.config.object_label_method)
              show_action = ::RailsAdmin::Config::Actions.find_visible(
                abstract_model: abstract_model,
                object: object,
                controller: bindings[:controller]
              )
              if show_action.nil?
               label
              else
                url = url_for(
                  action: show_action.action_name,
                  id: object.id,
                  model_name: abstract_model.to_param
                )
                link_to(label, url, class: 'pjax')
              end
            end
          end
          sortable true
          visible do
            bindings[:controller].params[:action] == 'history_index'
          end
        end
        field :message do
          label I18n.t('admin.table_headers.message')
          pretty_value do
            object = bindings[:object]
            if ['delete', 'new'].include?(object.message)
              I18n.t("admin.actions.#{object.message}.done").capitalize
            else
              object.message
            end
          end
          sortable true
        end
      end
      section
    end
  end
end
