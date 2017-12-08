module RailsAdmin
  module Config
    module Presenters
      class IndexPresenter
        def initialize(abstract_model:,
                       model_config:,
                       view_context:)
          @abstract_model = abstract_model
          @view_context = view_context
          @model_config = model_config
          @origin_params = view_context.request.params.dup
          @config = RailsAdmin::Config
          @actions = RailsAdmin::Config::Actions
        end

        # ASKS ----------------------------------------------------------------

        def sort_selected?(name)
          origin_sort == name
        end

        def checkboxes?
          @model_config.list.checkboxes?
        end

        def scopes?
          @model_config.list.scopes.any?
        end

        def sort_reverse?
          sort_reverse == 'true'
        end

        # TELLS ---------------------------------------------------------------

        def query
          params[:query]
        end

        # def sort
        #   params[:sort]
        # end

        def sort_reverse
          params[:sort_reverse]
        end

        def get_column_sets(properties = visible_fields)
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
              break if current_set_width >= @config.total_columns_width || property_index >= properties.length
            end
            set_index += 1
          end
          sets
        end

        def params
          @params ||=
            begin
              except_keys = [
                :authenticity_token,
                :action,
                :controller,
                :utf8,
                :bulk_export,
                :_pjax
              ]
              lparams = @origin_params.except(*except_keys)
              lparams.delete(:query) if lparams[:query].blank?
              lparams.delete(:sort_reverse) unless lparams[:sort_reverse] == 'true'
              lparams.delete(:sort) if lparams[:sort] == @model_config.list.sort_by.to_s
              lparams
            end
        end

        def model_description
          @config.model(@abstract_model.model_name).description
        end

        def export_action
          bindings = {
            controller: @view_context.controller,
            abstract_model: @abstract_model
          }
          @actions.find(:export, bindings)
        end

        def export_params
          params.except(:set, :page)
        end

        def index_params
          params.except(:page, :f, :query)
        end

        def index_with_scope_params(scope)
          params.merge(
            scope: scope,
            page: nil
          )
        end

        def sort_direction(sort)
          return unless sort_selected?(sort)
          sort_reverse? ? 'headerSortUp' : 'headerSortDown'
        end

        def index_with_sort_params(sort)
          reverse_params =
            if sort_selected?(sort) && !sort_reverse?
              { sort_reverse: "true" }
            else
              {}
            end
          params
            .except(:sort_reverse, :page)
            .merge(sort: sort)
            .merge(reverse_params)
        end

        private

        def visible_fields
          bindings = {
            controller: @view_context.controller,
            view: @view_context,
            object: @abstract_model.model.new
          }
          @model_config
            .list
            .with(bindings)
            .visible_fields
        end

        def origin_sort
          @origin_params[:sort]
        end
      end
    end
  end
end
