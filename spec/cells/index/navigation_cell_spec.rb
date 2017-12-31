require 'spec_helper'

describe RailsAdmin::NavigationCell, type: :view do
  let(:cell) do
    lview = view.extend(RailsAdmin::ApplicationHelper)
    described_class.new(lview)
  end

  context '#render_main_navigation' do
    it 'shows included models' do
      RailsAdmin.config do |config|
        config.included_models = [Ball, Comment]
      end
      actual = cell[:main_navigation]
      expect(actual).to match(/(dropdown-header).*(Navigation).*(Balls).*(Comments)/m)
    end

    it 'does not draw empty navigation labels' do
      RailsAdmin.config do |config|
        config.included_models = [Ball, Comment, Comment::Confirmed]
        config.model Comment do
          navigation_label 'Commentz'
        end
        config.model Comment::Confirmed do
          label_plural 'Confirmed'
        end
      end
      actual = cell[:main_navigation]
      expected = /(dropdown-header).*(Navigation).*(Balls).*(Commentz).*(Confirmed)/m
      expect(actual).to match(expected)
      not_expected = /(dropdown-header).*(Navigation).*(Balls).*(Commentz).*(Confirmed).*(Comment)/m
      expect(actual).not_to match(not_expected)
    end

    it 'does not show unvisible models' do
      RailsAdmin.config do |config|
        config.included_models = [Ball, Comment]
        config.model Comment do
          hide
        end
      end
      expect(cell[:main_navigation]).to match(/(dropdown-header).*(Navigation).*(Balls)/m)
      expect(cell[:main_navigation]).not_to match('Comments')
    end

    it 'shows children of hidden models' do # https://github.com/sferik/rails_admin/issues/978
      RailsAdmin.config do |config|
        config.included_models = [Ball, Hardball]
        config.model Ball do
          hide
        end
      end
      actual = cell[:main_navigation]
      expect(actual).to match(/(dropdown\-header).*(Navigation).*(Hardballs)/m)
    end

    it 'shows children of excluded models' do
      RailsAdmin.config do |config|
        config.included_models = [Hardball]
      end
      actual = cell[:main_navigation]
      expect(actual).to match(/(dropdown-header).*(Navigation).*(Hardballs)/m)
    end

    it 'nests in navigation label' do
      RailsAdmin.config do |config|
        config.included_models = [Comment]
        config.model Comment do
          navigation_label 'commentable'
        end
      end
      actual = cell[:main_navigation]
      expect(actual).to match(/(dropdown\-header).*(Commentable).*(Comments)/m)
    end

    it 'nests in parent model' do
      RailsAdmin.config do |config|
        config.included_models = [Player, Comment]
        config.model Comment do
          parent Player
        end
      end
      actual = cell[:main_navigation]
      expect(actual).to match(/(Players).* (nav\-level\-1).*(Comments)/m)
    end

    it 'orders' do
      RailsAdmin.config do |config|
        config.included_models = [Player, Comment]
      end
      expect(cell[:main_navigation]).to match(/(Comments).*(Players)/m)

      RailsAdmin.config(Comment) do
        weight 1
      end
      expect(cell[:main_navigation]).to match(/(Players).*(Comments)/m)
    end
  end

  context '#render_static_navigation' do
    it 'shows not show static nav if no static links defined' do
      RailsAdmin.config do |config|
        config.navigation_static_links = {}
      end

      expect(cell[:static_navigation]).to be_empty
    end

    it 'shows links if defined' do
      RailsAdmin.config do |config|
        config.navigation_static_links = {
          'Test Link' => 'http://www.google.com',
        }
      end
      expect(cell[:static_navigation]).to match(/Test Link/)
    end

    it 'shows default header if navigation_static_label not defined in config' do
      RailsAdmin.config do |config|
        config.navigation_static_links = {
          'Test Link' => 'http://www.google.com',
        }
      end
      expect(cell[:static_navigation]).to match(I18n.t('admin.misc.navigation_static_label'))
    end

    it 'shows custom header if defined' do
      RailsAdmin.config do |config|
        config.navigation_static_label = 'Test Header'
        config.navigation_static_links = {
          'Test Link' => 'http://www.google.com',
        }
      end
      expect(cell[:static_navigation]).to match(/Test Header/)
    end
  end
end
