module RailsAdmin
  module Config
    module Actions
      class << self
        def all(scope = :all, bindings = {})
          ActiveSupport::Deprecation.warn(
            "Method 'all' is deprecated and will be removed in Rails Admin major release.")

          if scope.is_a?(Hash)
            bindings = scope
            scope = :all
          end
          case scope
          when :all
            select(bindings)
          when :root, :collection, :bulkable, :member
            select(bindings, &:"#{scope}?")
          end
        end

        def select(bindings = {}, &scope)
          init_actions!

          actions =
            if block_given?
              @@actions.values.select(&scope)
            else
              @@actions.values
            end

          return actions if bindings.empty?

          actions = actions.map { |action| action.with(bindings) }
          bindings[:controller] ? actions.select(&:visible?) : actions
        end

        def find(custom_key, bindings = {})
          init_actions!
          action = @@actions[custom_key]

          return if action.nil?

          action = action.with(bindings)

          return if bindings[:controller] && action.hidden?

          action
        end

        def collection(key, parent_class = :base, &block)
          add_action(key, parent_class, :collection, &block)
        end

        def member(key, parent_class = :base, &block)
          add_action(key, parent_class, :member, &block)
        end

        def root(key, parent_class = :base, &block)
          add_action(key, parent_class, :root, &block)
        end

        def add_action(key, parent_class, parent, &block)
          action = RailsAdmin::Config::Actions.const_get(parent_class.to_s.camelize).new
          action.instance_eval(%(
            #{parent} true
            def key
              :#{key}
            end
          ))
          add_action_custom_key(action, &block)
        end

        def reset
          @@actions = nil
        end

        def register(klass)
          self.class.send(:define_method, klass.to_s.demodulize.underscore.to_sym) do |&block|
            add_action_custom_key(klass.new, &block)
          end
        end

      private

        def init_actions!
          @@actions ||= {
            dashboard: Dashboard.new,
            index: Index.new,
            show: Show.new,
            new: New.new,
            edit: Edit.new,
            export: Export.new,
            delete: Delete.new,
            bulk_delete: BulkDelete.new,
            history_show: HistoryShow.new,
            history_index: HistoryIndex.new,
            show_in_app: ShowInApp.new,
          }
        end

        def add_action_custom_key(action, &block)
          action.instance_eval(&block) if block_given?
          @@actions ||= {}
          if @@actions.key?(action.custom_key)
            raise ::RailsAdmin::Errors::ActionAlreadyRegistred, action
          else
            @@actions[action.custom_key] = action
          end
        end
      end
    end
  end
end

require 'rails_admin/config/actions/base'
require 'rails_admin/config/actions/dashboard'
require 'rails_admin/config/actions/index'
require 'rails_admin/config/actions/show'
require 'rails_admin/config/actions/show_in_app'
require 'rails_admin/config/actions/history_show'
require 'rails_admin/config/actions/history_index'
require 'rails_admin/config/actions/new'
require 'rails_admin/config/actions/edit'
require 'rails_admin/config/actions/export'
require 'rails_admin/config/actions/delete'
require 'rails_admin/config/actions/bulk_delete'
