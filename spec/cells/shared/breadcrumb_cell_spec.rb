require 'spec_helper'

describe RailsAdmin::Shared::BreadcrumbCell, type: :view do
  def cell(model)
    lview = view.extend(RailsAdmin::ApplicationHelper)
    described_class.new(lview, model)
  end

  describe '#render_show' do
    it 'returns a breadcrumb' do
      abstract_model = RailsAdmin::AbstractModel.new(Team)
      object = FactoryGirl.create(:team, name: 'the avengers')

      bindings = {
        abstract_model: abstract_model,
        object: object,
        controller: controller
      }
      action = RailsAdmin::Config::Actions.find_visible(:edit, bindings)

      html = cell(abstract_model)[:show, action, object]
      page = Capybara::Node::Simple.new(html)
      expect(page.find_all('li').map(&:text)).to eql(
        [
          'Dashboard',
          'Teams',
          'The avengers',
          'Edit',
        ])
      expect(page.find('li.active').text).to eql('Edit')
    end
  end

  # describe '#private.current_action?' do
  #   it 'returns true if current_action, false otherwise' do
  #     current_action = RailsAdmin::Config::Actions.find(:index)
  #     other_action = RailsAdmin::Config::Actions.find(:show)
  #
  #     actual = cell(nil).send(:current_action?, current_action, nil, nil, current_action, nil)
  #     expect(actual).to be_truthy
  #
  #     actual = cell(nil).send(:current_action?, other_action, nil, nil, current_action, nil)
  #     expect(actual).to be_falsey
  #   end
  # end
end
