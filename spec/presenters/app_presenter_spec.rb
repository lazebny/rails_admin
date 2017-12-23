require 'spec_helper'

describe RailsAdmin::AppPresenter do
  let(:controller) { OpenStruct.new }
  let(:view_context) { OpenStruct.new }
  let(:presenter) { described_class.new(controller, view_context) }

  describe '#plugin_name' do
    it 'works by default' do
      expect(presenter.plugin_full_name).to eq('Dummy App Admin')
    end

    it 'works for static names' do
      RailsAdmin.config do |config|
        config.main_app_name = %w(static value)
      end
      expect(presenter.plugin_full_name).to eq('static value')
    end

    it 'works for dynamic names in the controller context' do
      RailsAdmin.config do |config|
        config.main_app_name = proc do
          [
            Rails.application.engine_name.titleize,
            action_name.titleize
          ]
        end
      end
      controller.action_name = 'dashboard'
      expect(presenter.plugin_full_name).to eq('Dummy App Application Dashboard')
    end
  end
end
