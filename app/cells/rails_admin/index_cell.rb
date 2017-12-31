module RailsAdmin
  class IndexCell < BaseCell
    delegate(
      :content_tag,
      to: :view_context
    )

    delegate(
      :description,
      to: :model_config
    )

    def render_description
      return unless description.present?

      content_tag(:p) { content_tag(:strong, description) }
    end

    private

    # FIXME: remove
    # def params
    #   @params ||=
    #     begin
    #       except_keys = [
    #         :authenticity_token,
    #         :action,
    #         :controller,
    #         :utf8,
    #         :bulk_export,
    #         :_pjax
    #       ]
    #       lparams = origin_params.except(*except_keys)
    #       lparams.delete(:query) if lparams[:query].blank?
    #       lparams.delete(:sort_reverse) unless lparams[:sort_reverse] == 'true'
    #       lparams.delete(:sort) if lparams[:sort] == model_config.list.sort_by.to_s
    #       lparams
    #     end
    # end
  end
end
