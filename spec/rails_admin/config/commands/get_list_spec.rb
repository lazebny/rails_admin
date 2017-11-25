require 'spec_helper'

describe RailsAdmin::Config::Commands::GetList do
  let(:instance) { described_class.new }

  describe '#call' do
    let(:model_config) { RailsAdmin.config(Team) }

    before do
      RailsAdmin.config Team do
        field :players do
          eager_load true
        end
      end
    end

    it 'performs eager-loading for an association field with `eagar_load true`' do
      scope = double('scope')
      abstract_model = model_config.abstract_model
      params = { model_name: 'teams' }
      allow(model_config).to receive(:abstract_model).and_return(abstract_model)
      expect(abstract_model).to receive(:all).with(hash_including(include: [:players]), scope).once
      instance.call(params, model_config, scope, false)
    end
  end

  describe '#get_sort_hash' do
    context 'options sortable is a hash' do
      before do
        RailsAdmin.config('Player') do
          configure :team do
            sortable do
              :'team.name'
            end
          end
        end
      end

      it 'returns the option with no changes' do
        params = {sort: 'team', model_name: 'players'}
        expect(instance.send(:get_sort_hash, params, RailsAdmin.config(Player)))
          .to eq(sort: :"team.name", sort_reverse: true)
      end
    end

    it 'works with belongs_to associations with label method virtual' do
      params = {sort: 'parent_category', model_name: 'categories'}
      expect(instance.send(:get_sort_hash, params, RailsAdmin.config(Category)))
        .to eq(sort: 'categories.parent_category_id', sort_reverse: true)
    end

    context 'using mongoid, not supporting joins', mongoid: true do
      it 'gives back the remote table with label name' do
        params = {sort: 'team', model_name: 'players'}
        expect(instance.send(:get_sort_hash, params, RailsAdmin.config(Player)))
          .to eq(sort: 'players.team_id', sort_reverse: true)
      end
    end

    context 'using active_record, supporting joins', active_record: true do
      it 'gives back the local column' do
        params = {sort: 'team', model_name: 'players'}
        expect(instance.send(:get_sort_hash, params, RailsAdmin.config(Player)))
          .to eq(sort: 'teams.name', sort_reverse: true)
      end
    end
  end
end
