module RailsAdmin
  class PaginationCell < BaseCell
    delegate(
      :content_tag,
      :link_to,
      :paginate,
      :params,
      :t,
      to: :view_context
    )

    def render_show(objects)
      return render_limited_pagination(objects) if model_config.list.limited_pagination

      return join_renders(
        render_with_count(objects),
        render_total_count(objects.total_count.to_i)
      ) if objects.respond_to?(:total_count)

      render_total_count(objects.size)
    end

    private

    def with_pagination_wrapper(&block)
      content_tag(:div, class: 'row') do
        content_tag(:div, class: 'col-md-6') do
          block.call
        end
      end
    end

    def render_total_count(total_count)
      content_tag(:div, class: 'clearfix total-count') do
        "#{total_count} #{model_config.pluralize(total_count).downcase}"
      end
    end

    def render_limited_pagination(objects)
      with_pagination_wrapper do
        paginate(objects,
                 theme: 'ra-twitter-bootstrap/without_count',
                 total_pages: Float::INFINITY,
                 remote: true)
      end
    end

    def render_with_count(objects)
      total_count = objects.total_count.to_i

      join_renders(
        (with_pagination_wrapper do
           paginate(objects, theme: 'ra-twitter-bootstrap', remote: true)
         end),
        (content_tag(:div, class: 'row') do
           content_tag(:div, class: 'col-md-6') do
             list_params = params.permit(
               :f,
               :query,
               :scope,
               :set,
               :sort,
               :sort_reverse,
             ).symbolize_keys
             list_params[:all] = true

             link_to(
               t("admin.misc.show_all"),
               current_path(list_params),
               class: "show-all btn btn-default clearfix pjax"
             )
           end
         end unless total_count > 100 || total_count <= objects.to_a.size)
      )
    end
  end
end
