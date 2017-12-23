require 'spec_helper'

describe RailsAdmin::ApplicationController, type: :controller do
  describe '#_current_user' do
    it 'is public' do
      expect { controller._current_user }.not_to raise_error
    end
  end

  describe '#rails_admin_controller?' do
    it 'returns true' do
      expect(controller.send(:rails_admin_controller?)).to be true
    end
  end
end
