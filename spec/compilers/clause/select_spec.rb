# frozen_string_literal: true

require_relative 'helper'

describe 'Compilers::Clause' do
  context 'SELECT' do
    subject { compile }
    let(:clause) { :select }

    # advanced tests will be in expressions
    context 'works=)' do
      let(:structure) { { u: [:role], _name: :full_name } }
      let(:result) { 'SELECT u.role, full_name AS name ' }
      it { is_expected.to eq result }
    end
  end
end
