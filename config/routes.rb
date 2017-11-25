RailsAdmin::Engine.routes.draw do
  controller 'main' do
    RailsAdmin::Config::Actions.select(&:root?).each do |action|
      match "/#{action.route_fragment}",
            action: action.action_name,
            as: action.action_name,
            via: action.http_methods
    end
    scope ':model_name' do
      RailsAdmin::Config::Actions.select(&:collection?).each do |action|
        match "/#{action.route_fragment}",
              action: action.action_name,
              as: action.action_name,
              via: action.http_methods
      end
      post '/bulk_action', action: :bulk_action, as: 'bulk_action'
      scope ':id' do
        RailsAdmin::Config::Actions.select(&:member?).each do |action|
          match "/#{action.route_fragment}",
                action: action.action_name,
                as: action.action_name,
                via: action.http_methods
        end
      end
    end
  end
end
