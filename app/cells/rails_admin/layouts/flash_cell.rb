module RailsAdmin
  module Layouts
    class FlashCell < BaseCell
      FLASH_CLASSES = {
        error: 'alert-danger',
        alert: 'alert-warning',
        notice: 'alert-info'
      }

      delegate(
        :content_tag,
        to: :view_context
      )

      def render_show(flash)
        return if flash.empty?

        join_renders(*flash.map(&method(:render_flash_item)))
      end

      private

      def render_flash_item((key, value))
        content_tag(:div, class: "alert alert-dismissible #{alert_class(key)}") do
          join_renders(
            content_tag(
              :button,
              '&times;'.html_safe,
              type: 'button',
              :'data-dismiss' => 'alert'
            ),
            value
          )
        end
      end

      def alert_class(key)
        FLASH_CLASSES.fetch(key.to_sym) { "alert-#{key}" }
      end
    end
  end
end
