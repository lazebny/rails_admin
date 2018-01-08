require 'spec_helper'

describe RailsAdmin::Shared::PluginCell, type: :helper do
  let(:cell) { described_class.new(controller.view_context) }

  describe '#plugin_name' do
    it 'works by default' do
      expect(cell.plugin_full_name).to eq('Dummy App Admin')
    end

    it 'works for static names' do
      RailsAdmin.config do |config|
        config.main_app_name = %w(static value)
      end
      expect(cell.plugin_full_name).to eq('static value')
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
      expect(cell.plugin_full_name).to eq('Dummy App Application Dashboard')
    end
  end
end
