module RailsAdmin
  module Extensions
    module PaperTrail
      class VersionProxy
        def initialize(version, user_class = User)
          @version = version
          @user_class = user_class
        end

        def message
          @message = @version.event
          @version.respond_to?(:changeset) && @version.changeset.present? ? @message + ' [' + @version.changeset.to_a.collect { |c| c[0] + ' = ' + c[1][1].to_s }.join(', ') + ']' : @message
        end

        def created_at
          @version.created_at
        end

        def table
          @version.item_type
        end

        def username
          @user_class.find(@version.whodunnit).try(:email) rescue nil || @version.whodunnit
        end

        def item
          @version.item_id
        end
      end
    end
  end
end
