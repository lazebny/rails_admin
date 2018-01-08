require 'spec_helper'

describe RailsAdmin::Layouts::Navigation::SecondaryNavigation::UserCell, type: :helper do
  let(:user) { OpenStruct.new }

  def cell(user)
    described_class.new(controller.view_context, user)
  end

  describe '#logout_method' do
    it 'defaults to :delete when Devise is not defined' do
      allow(Object).to receive(:defined?).with(Devise).and_return(false)

      expect(cell(user).send(:logout_method)).to eq(:delete)
    end

    it 'uses first sign out method from Devise when it is defined' do
      allow(Object).to receive(:defined?).with(Devise).and_return(true)

      expect(Devise).to receive(:sign_out_via)
        .and_return([:whatever_defined_on_devise, :something_ignored])
      expect(cell(user).send(:logout_method)).to eq(:whatever_defined_on_devise)
    end
  end


  describe '#edit_user_link' do
    it "don't include email column" do
      expect(cell(build(:player)).send(:edit_user_link)).to eq nil
    end

    it 'include email column' do
      expect(cell(create(:user)).send(:edit_user_link)).to match('href')
    end

    it 'show gravatar' do
      email = 'username_3@example.com'
      user = create(:user, email: email)

      expected = cell(user).send(:edit_user_link)
      actual =
        "<a href=\"http://test.host/admin/user/#{user.id}/edit\">" \
        "<img alt=\"\" src=\"http://www.gravatar.com/avatar/2bb5725c752d151f65f17081543ef934?s=30\" />" \
        "<span>#{email}" \
        "</span>" \
        "</a>"
      expect(expected).to eq(actual)
    end

    it "don't show gravatar" do
      RailsAdmin.config do |config|
        config.show_gravatar = false
      end

      user = create(:user)

      expected = cell(user).send(:edit_user_link)
      actual =
        "<a href=\"http://test.host/admin/user/#{user.id}/edit\">" \
        "<span>#{user.email}" \
        "</span>" \
        "</a>"
      expect(expected).to eq(actual)
    end
  end
end
