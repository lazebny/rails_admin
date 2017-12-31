require 'spec_helper'
require 'cancan'

class TestAbility
  include CanCan::Ability
  def initialize(_user)
    can :access, :rails_admin
    can :edit, FieldTest
    cannot :edit, FieldTest, string_field: 'dangerous'
  end
end

describe RailsAdmin::ApplicationHelper, type: :helper do
  describe '#authorized?' do
    before do
      allow(RailsAdmin.config).to receive(:_current_user).and_return(FactoryGirl.create(:user))
      allow(helper.controller).to receive(:authorization_adapter).and_return(RailsAdmin::AUTHORIZATION_ADAPTERS[:cancan].new(RailsAdmin.config, TestAbility))
    end

    it 'doesn\'t test unpersisted objects' do
      am = RailsAdmin.config(FieldTest).abstract_model
      expect(helper.authorized?(:edit, am, FactoryGirl.create(:field_test, string_field: 'dangerous'))).to be_falsey
      expect(helper.authorized?(:edit, am, FactoryGirl.create(:field_test, string_field: 'not-dangerous'))).to be_truthy
      expect(helper.authorized?(:edit, am, FactoryGirl.build(:field_test, string_field: 'dangerous'))).to be_truthy
    end
  end

  describe 'with #authorized? stubbed' do
    before do
      allow(controller).to receive(:authorized?).and_return(true)
    end

    describe '#current_action?' do
      it 'returns true if current_action, false otherwise' do
        current_action = RailsAdmin::Config::Actions.find(:index)
        actual = helper.current_action?(current_action, current_action)
        expect(actual).to be_truthy

        other_action = RailsAdmin::Config::Actions.find(:show)
        actual = helper.current_action?(other_action, current_action)
        expect(actual).not_to be_truthy
      end
    end

    describe '#action' do
      it 'returns action by :custom_key' do
        RailsAdmin.config do |config|
          config.actions do
            dashboard do
              custom_key :my_custom_dashboard_key
            end
          end
        end
        expect(helper.action(:my_custom_dashboard_key)).to be
      end

      it 'returns only visible actions' do
        RailsAdmin.config do |config|
          config.actions do
            dashboard do
              visible false
            end
          end
        end

        expect(helper.action(:dashboard)).to be_nil
      end

      it 'returns only visible actions, passing all bindings' do
        RailsAdmin.config do |config|
          config.actions do
            member :test_bindings do
              visible do
                bindings[:controller].is_a?(ActionView::TestCase::TestController) &&
                  bindings[:abstract_model].model == Team &&
                  bindings[:object].is_a?(Team)
              end
            end
          end
        end
        expect(helper.action(:test_bindings, RailsAdmin::AbstractModel.new(Team), Team.new)).to be
        expect(helper.action(:test_bindings, RailsAdmin::AbstractModel.new(Team), Player.new)).to be_nil
        expect(helper.action(:test_bindings, RailsAdmin::AbstractModel.new(Player), Team.new)).to be_nil
      end
    end

    describe '#actions' do
      it 'returns actions by type' do
        abstract_model = RailsAdmin::AbstractModel.new(Player)
        object = FactoryGirl.create :player
        expect(helper.actions(:all, abstract_model, object).collect(&:custom_key)).to eq([:dashboard, :index, :show, :new, :edit, :export, :delete, :bulk_delete, :history_show, :history_index, :show_in_app])
        expect(helper.actions(:root, abstract_model, object).collect(&:custom_key)).to eq([:dashboard])
        expect(helper.actions(:collection, abstract_model, object).collect(&:custom_key)).to eq([:index, :new, :export, :bulk_delete, :history_index])
        expect(helper.actions(:member, abstract_model, object).collect(&:custom_key)).to eq([:show, :edit, :delete, :history_show, :show_in_app])
      end

      it 'only returns visible actions, passing bindings correctly' do
        RailsAdmin.config do |config|
          config.actions do
            member :test_bindings do
              visible do
                bindings[:controller].is_a?(ActionView::TestCase::TestController) &&
                  bindings[:abstract_model].model == Team &&
                  bindings[:object].is_a?(Team)
              end
            end
          end
        end

        expect(helper.actions(:all, RailsAdmin::AbstractModel.new(Team), Team.new).collect(&:custom_key)).to eq([:test_bindings])
        expect(helper.actions(:all, RailsAdmin::AbstractModel.new(Team), Player.new).collect(&:custom_key)).to eq([])
        expect(helper.actions(:all, RailsAdmin::AbstractModel.new(Player), Team.new).collect(&:custom_key)).to eq([])
      end
    end

    describe '#wording_for' do
      it 'gives correct wording even if action is not visible' do
        RailsAdmin.config do |config|
          config.actions do
            index do
              visible false
            end
          end
        end

        expect(helper.wording_for(:menu, :index)).to eq('List')
      end

      it 'passes correct bindings' do
        expect(helper.wording_for(:title, :edit, RailsAdmin::AbstractModel.new(Team), Team.new(name: 'the avengers'))).to eq("Edit Team 'the avengers'")
      end

      it 'defaults correct bindings' do
        @action = RailsAdmin::Config::Actions.find :edit
        @abstract_model = RailsAdmin::AbstractModel.new(Team)
        @object = Team.new(name: 'the avengers')
        expect(helper.wording_for(:title)).to eq("Edit Team 'the avengers'")
      end

      it 'does not try to use the wrong :label_metod' do
        @abstract_model = RailsAdmin::AbstractModel.new(Draft)
        @object = Draft.new

        expect(helper.wording_for(:link, :new, RailsAdmin::AbstractModel.new(Team))).to eq('Add a new Team')
      end
    end

    describe '#menu_for' do
      it 'passes model and object as bindings and generates a menu, excluding non-get actions' do
        RailsAdmin.config do |config|
          config.actions do
            dashboard
            index do
              visible do
                bindings[:abstract_model].model == Team
              end
            end
            show do
              visible do
                bindings[:object].class == Team
              end
            end
            delete do
              http_methods [:post, :put, :delete]
            end
          end
        end

        @action = RailsAdmin::Config::Actions.find :show
        @abstract_model = RailsAdmin::AbstractModel.new(Team)
        @object = FactoryGirl.create(:team, name: 'the avengers')

        expect(helper.menu_for(:root)).to match(/Dashboard/)
        expect(helper.menu_for(:collection, @abstract_model)).to match(/List/)
        expect(helper.menu_for(:member, @abstract_model, @object)).to match(/Show/)

        @abstract_model = RailsAdmin::AbstractModel.new(Player)
        @object = Player.new
        expect(helper.menu_for(:collection, @abstract_model)).not_to match(/List/)
        expect(helper.menu_for(:member, @abstract_model, @object)).not_to match(/Show/)
      end

      it 'excludes non-get actions' do
        RailsAdmin.config do |config|
          config.actions do
            dashboard do
              http_methods [:post, :put, :delete]
            end
          end
        end

        @action = RailsAdmin::Config::Actions.find :dashboard
        expect(helper.menu_for(:root)).not_to match(/Dashboard/)
      end
    end
  end

  describe '#flash_alert_class' do
    it 'makes errors red with alert-danger' do
      expect(helper.flash_alert_class('error')).to eq('alert-danger')
    end
    it 'makes alerts yellow with alert-warning' do
      expect(helper.flash_alert_class('alert')).to eq('alert-warning')
    end
    it 'makes notices blue with alert-info' do
      expect(helper.flash_alert_class('notice')).to eq('alert-info')
    end
    it 'prefixes others with "alert-"' do
      expect(helper.flash_alert_class('foo')).to eq('alert-foo')
    end
  end
end
