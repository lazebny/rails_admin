module RailsAdmin
  module Config
    module Commands
      class GetList
        def initialize
          @association_field = ::RailsAdmin::Config::Fields::Association
          @paginator_class = ::Kaminari
        end

        def call(params, model_config, scope, pagination)
          associations =
            model_config
            .list
            .fields
            .select(&@association_field.method(:===))
            .select(&:eager_load?)
            .map { |f| f.association.name }

          options = {}
          if pagination
            options = options.merge(page: (params[@paginator_class.config.param_name] || 1).to_i,
                                    per: (params[:per] || model_config.list.items_per_page))
          end
          options = options.merge(include: associations) unless associations.blank?
          options = options.merge(sort_hash(params, model_config))
          options = options.merge(query: params[:query]) if params[:query].present?
          options = options.merge(filters: params[:f]) if params[:f].present?
          options = options.merge(bulk_ids: params[:bulk_ids]) if params[:bulk_ids]
          model_config.abstract_model.all(options, scope)
        end

        private

        def sort_hash(params, model_config)
          abstract_model = model_config.abstract_model

          field = nil
          sort = params[:sort]

          field = sort_field(sort, model_config) unless sort.nil?

          if field.nil?
            sort = model_config.list.sort_by
            field = sort_field(sort, model_config)
          end

          sort_column =
            if field.nil? || field.sortable == true # use params[:sort] on the base table
              "#{abstract_model.table_name}.#{sort}"
            elsif field.sortable == false # use default sort, asked field is not sortable
              "#{abstract_model.table_name}.#{model_config.list.sort_by}"
            elsif (field.sortable.is_a?(String) || field.sortable.is_a?(Symbol)) && field.sortable.to_s.include?('.') # just provide sortable, don't do anything smart
              field.sortable
            elsif field.sortable.is_a?(Hash) # just join sortable hash, don't do anything smart
              "#{field.sortable.keys.first}.#{field.sortable.values.first}"
            elsif field.association? # use column on target table
              "#{field.associated_model_config.abstract_model.table_name}.#{field.sortable}"
            else # use described column in the field conf.
              "#{abstract_model.table_name}.#{field.sortable}"
            end

          sort_reverse = params[:sort_reverse] || 'false'
          reversed_sort = (field ? field.sort_reverse? : model_config.list.sort_reverse?)
          {
            sort: sort_column,
            sort_reverse: (sort_reverse == reversed_sort.to_s)
          }
        end

        def sort_field(sort, model_config)
          return if sort.nil?

          model_config
            .list
            .fields
            .find { |f| f.name == sort.to_sym }
        end
      end
    end
  end
end
