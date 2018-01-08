require 'spec_helper'

describe RailsAdmin::Layouts::FlashCell, type: :view do
  let(:cell) { described_class.new(view) }

  describe 'private#alert_class' do
    it 'makes errors red with alert-danger' do
      expect(cell.send(:alert_class, :error)).to eq('alert-danger')
    end
    it 'makes alerts yellow with alert-warning' do
      expect(cell.send(:alert_class, :alert)).to eq('alert-warning')
    end
    it 'makes notices blue with alert-info' do
      expect(cell.send(:alert_class, :notice)).to eq('alert-info')
    end
    it 'prefixes others with "alert-"' do
      expect(cell.send(:alert_class, :foo)).to eq('alert-foo')
    end
  end
end
