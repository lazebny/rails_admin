module RailsAdmin
  module Config
    module Actions
      class << self
        # Deprecated
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

        def select(&scope)
          return actions.values.select(&scope) if block_given?

          actions.values
        end

        def select_visible(bindings, &scope)
          lactions = select(&scope).map { |action| action.with(bindings) }

          return lactions unless bindings[:controller]

          lactions.select(&:visible?)
        end

        def find(action_name)
          actions[action_name]
        end

        def find_visible(action_name, bindings = {})
          action = find(action_name)

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

        def actions
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
          @@actions ||= {}

          action.instance_eval(&block) if block_given?

          if actions.key?(action.custom_key)
            raise ::RailsAdmin::Errors::ActionAlreadyRegistred, action
          else
            actions[action.custom_key] = action
          end
        end
      end
    end
  end
end

RailsAdmin::Support::FileHelper.require_relative(__FILE__, 'actions', 'base.rb')
RailsAdmin::Support::FileHelper.require_relative(__FILE__, 'actions', '*.rb')
