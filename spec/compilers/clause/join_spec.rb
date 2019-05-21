# frozen_string_literal: true

require_relative 'helper'

describe 'Compilers::Clause' do
  context 'JOIN' do
    subject { compile }
    let(:clause) { :join }

    # advanced tests will be in expressions
    context 'Hash' do
      context 'with values as condition' do
        let(:structure) { { [:users, :u] => { u__id: :r__user_id } } }
        let(:result) { 'JOIN users AS u ON u.id = r.user_id ' }
        it { is_expected.to eq result }
      end

      context 'with values as options' do
        let(:structure) do
          { [:users, :u] => { on: { u__id: :r__user_id },
                              type: :left } }
        end
        let(:result) { 'LEFT JOIN users AS u ON u.id = r.user_id ' }
        it { is_expected.to eq result }
      end
    end

    context 'Array' do
      let(:structure) do
        [{ [:users, :u] => { u__id: :r__user_id } },
         { [{ select: :* }, :m] => { m__user_id: :u__id } }]
      end
      let(:result) do
        'JOIN users AS u ON u.id = r.user_id JOIN (SELECT * ) AS m ON m.user_id = u.id '
      end
      it { is_expected.to eq result }
    end

    context 'String' do
      let(:structure) { 'SOME CRAZY JOIN epic_table ON TRUE' }
      let(:result) { structure }
      it { is_expected.to eq result }
    end
  end
end
