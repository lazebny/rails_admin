require 'spec_helper'

describe RailsAdmin::Index::FiltersCell, type: :view do
  def cell(model)
    lview = view.extend(RailsAdmin::ApplicationHelper)
    described_class.new(lview, model)
  end

  describe '#render_bulk_menu' do
    it 'includes all visible bulkable actions' do
      RailsAdmin.config do |config|
        config.actions do
          index
          collection :zorg do
            bulkable true
            action_name :zorg_action
          end
          collection :blub do
            bulkable true
            visible do
              bindings[:abstract_model].model == Team
            end
          end
        end
      end
      actual = cell(RailsAdmin::AbstractModel.new(Team))[:bulk_menu]
      expect(actual).to match('zorg_action')
      expect(actual).to match('blub')

      expect(cell(RailsAdmin::AbstractModel.new(Player))[:bulk_menu]).not_to match('blub')
    end
  end
end
