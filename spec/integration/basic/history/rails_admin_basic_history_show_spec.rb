# coding: utf-8

require 'spec_helper'

RSpec::Matchers.define :have_history_rows_on_show_page do |histories|
  def expected_list_item(history)
    [
      format_date(history.created_at),
      history.username,
      history.message
    ]
  end

  def row_elements(elements)
    elements.map(&:text).each_slice(3).to_a
  end

  def format_date(date)
    I18n.l(date, format: :long, default: I18n.l(date, format: :long))
  end

  match do |actual|
    lactual = row_elements(actual.find_all('tr td'))
    lexpected = histories.map { |hist| expected_list_item(hist) }
    lactual == lexpected
  end
end

describe 'RailsAdmin Basic History Index Spec', type: :request do
  subject { page }

  let(:player_model) { RailsAdmin::AbstractModel.new('Player') }
  let(:player_object) { FactoryGirl.create(:player) }
  let(:current_user) { FactoryGirl.build(:user) }

  def create_player_history(model: player_model, object: player_object, user: current_user, count: 1)
    count.times.map do |index|
      object.number = index
      RailsAdmin::History.create_history_item("change #{index}", object, model, user)
    end
  end

  def within_history(&block)
    within('#history', &block)
  end

  def row_elements(elements)
    elements.map(&:text).each_slice(3).to_a
  end

  def header_location(hclass)
    find("th.header.#{hclass}")['data-href']
  end

  def show_player_history_path(player, **opts)
    history_show_path(opts.merge(model_name: 'player', id: player.id))
  end

  describe 'GET /admin/player/:id/history' do
    it '' do
      histories = create_player_history(count: 5, object: player_object)
      visit show_player_history_path(player_object)

      within_history do
        actual = row_elements(find_all('tr th')).first
        expected = ['Date/Time', 'User', 'Message']
        expect(actual).to eq(expected)

        is_expected.to have_history_rows_on_show_page(histories.reverse, player_object)
      end
    end
  end

  describe 'GET /admin/player/:id/history with pagination' do
    let(:items_per_page) { 1 }

    def create_record
      create_player_history
    end

    def page_path(**opts)
      show_player_history_path(player_object, opts)
    end

    it_behaves_like :default_pagination_examples
    it_behaves_like :limited_pagination_examples do
      before do
        list = RailsAdmin::AbstractModel.new(Player).config.list
        allow(list).to receive(:limited_pagination).and_return(true)
      end
    end
  end

  describe 'GET /admin/player/:id/history?sort=message&sort_reverse=true' do
    it 'displays rows in proper order' do
      histories = create_player_history(count: 5, object: player_object)
      visit show_player_history_path(player_object, sort: :message, sort_reverse: true)

      within_history do
        expect(header_location('message_field'))
          .to eql(show_player_history_path(player_object, sort: :message))
        is_expected.to have_css('th.header.message_field.headerSortUp')
        is_expected.to have_history_rows_on_show_page(histories.reverse, player_object)
      end
    end
  end

  describe 'GET /admin/player/:id/history?sort=message&sort_reverse=false' do
    it 'displays rows in proper order' do
      histories = create_player_history(count: 5, object: player_object)
      visit show_player_history_path(player_object, sort: :message, sort_reverse: false)

      within_history do
        expect(header_location('message_field'))
          .to eql(show_player_history_path(player_object, sort: :message, sort_reverse: true))
        is_expected.to have_css('th.header.message_field.headerSortDown')
        is_expected.to have_history_rows_on_show_page(histories, player_object)
      end
    end
  end

  describe 'GET /admin/player/:id/history?query=message' do
    it 'displays rows with filter' do
      histories = create_player_history(count: 5, object: player_object)
      history = histories.last
      visit show_player_history_path(player_object, query: history.message)

      within_history do
        expect(header_location('message_field'))
          .to eql(show_player_history_path(player_object, query: history.message, sort: :message))
        is_expected.to have_history_rows_on_show_page([history], player_object)
      end
    end
  end
end
