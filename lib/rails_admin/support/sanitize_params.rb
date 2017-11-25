module RailsAdmin
  module Support
    class SanitizeParams
      # Mutates target_params object
      def call(action, model_config, target_params, bindings)
        return unless target_params.present?

        fields = visible_fields(action, model_config, bindings)

        fields.each { |field| field.parse_input(target_params) }

        target_params.slice!(*allowed_methods(fields))

        target_params.permit! if target_params.respond_to?(:permit!)

        fields.select(&:nested_form).each do |association|
          children_params(association, target_params).each do |children_param|
            call(:nested, association.associated_model_config, children_param, bindings)
          end
        end
      end

      private

      def children_params(association, target_params)
        if association.multiple?
          target_params[association.method_name].try(:values) || []
        else
          [target_params[association.method_name]].compact
        end
      end

      def visible_fields(action, model_config, bindings)
        model_config
          .send(action)
          .with(bindings)
          .visible_fields
      end

      def allowed_methods(fields)
        fields
        .map(&:allowed_methods)
        .flatten
        .uniq
        .collect(&:to_s) + ['id', '_destroy']
      end
    end
  end
end
