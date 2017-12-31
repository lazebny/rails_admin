module RailsAdmin
  module Index
    class PaginationCell < BaseCell
      delegate(
        :content_tag,
        :link_to,
        :paginate,
        :params,
        :t,
        to: :view_context
      )

      delegate(
        :index_path,
        to: :rails_admin
      )

      def render_show(objects)
        view = nil

        if objects.respond_to?(:total_count)
          view = render_with_count(objects)
          total_count = objects.total_count.to_i
        else
          total_count = objects.size
        end

        join_renders(
          view,
          content_tag(:div, class: 'clearfix total-count') do
            "#{total_count} #{model_config.pluralize(total_count).downcase}"
          end
        )
      end

      private

      def render_with_count(objects)
        total_count = objects.total_count.to_i

        join_renders(
          (content_tag(:div, class: 'row') do
              content_tag(:div, class: 'col-md-6') do
                paginate(objects, theme: 'ra-twitter-bootstrap', remote: true)
              end
            end),
          (content_tag(:div, class: 'row') do
             content_tag(:div, class: 'col-md-6') do
               index_params = params.permit(
                 :f,
                 :query,
                 :scope,
                 :set,
                 :sort,
                 :sort_reverse,
               )
               index_params[:all] = true

               link_to(
                 t("admin.misc.show_all"),
                 index_path(index_params),
                 class: "show-all btn btn-default clearfix pjax"
               )
             end
           end unless total_count > 100 || total_count <= objects.to_a.size)
        )
      end
    end
  end
end
