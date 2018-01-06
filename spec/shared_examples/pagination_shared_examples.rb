RSpec::Matchers.define :have_pagination_prev_link do |expected|
  match { |actual| actual.find('li:first a').has_content?('« Prev') }
end

RSpec::Matchers.define :have_pagination_next_link do |expected|
  match { |actual| actual.find('li:last a').has_content?('Next »') }
end

RSpec::Matchers.define :have_pagination_active_page_link do |expected|
  match do |actual|
    link = actual.find('li.active a')
    results = [
      link.has_content?(expected),
      link['href'] == page_path(expected > 1 ? { page: expected } : {} )
    ]
    results.all?
  end
end

RSpec.shared_examples :default_pagination_examples do
  # Overrides:
  #   def create_record => Record
  #   def page_path(page: page_num) => String
  #   let items_per_page => Integer

  describe 'with limited_pagination=false' do
    before do
      RailsAdmin.config.default_items_per_page = items_per_page
      (items_per_page * 3).times { create_record }
    end

    it 'page 1' do
      visit page_path

      within('ul.pagination') do
        is_expected.to have_pagination_prev_link
        is_expected.to have_pagination_next_link
        is_expected.to have_pagination_active_page_link(1)
      end
    end

    it 'page 2' do
      visit page_path(page: 2)

      within('ul.pagination') do
        is_expected.to have_pagination_prev_link
        is_expected.to have_pagination_next_link
        is_expected.to have_pagination_active_page_link(2)
      end
    end

    it 'page 3' do
      visit page_path(page: 3)

      within('ul.pagination') do
        is_expected.to have_pagination_prev_link
        is_expected.to have_pagination_next_link
        is_expected.to have_pagination_active_page_link(3)
      end
    end
  end
end

RSpec.shared_examples :limited_pagination_examples do
  # Overrides:
  #   def create_record => Record
  #   def page_path(page: page_num) => String
  #   let items_per_page => Integer

  describe 'with limited_pagination' do
    before do
      RailsAdmin.config.default_items_per_page = items_per_page
      (items_per_page * 3).times { create_record }
    end

    it 'page 1' do
      visit page_path

      within('ul.pagination') do
        is_expected.not_to have_pagination_prev_link
        is_expected.to have_pagination_next_link
      end
    end

    it 'page 2' do
      visit page_path(page: 2)

      within('ul.pagination') do
        is_expected.to have_pagination_prev_link
        is_expected.to have_pagination_next_link
      end
    end

    it 'page 3' do
      visit page_path(page: 3)

      within('ul.pagination') do
        is_expected.to have_pagination_prev_link
        is_expected.to have_pagination_next_link
      end
    end
  end
end
