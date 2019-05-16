# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Compilers::Table' do
  subject { Terrazine::Compiler.compile_tables(structure) }

  # God damn it... everything wrong...-_-
  context 'Array' do
    context 'as Operator' do
      let(:structure) { [:_values, 'Aeonax'] }
      let(:result) { "(VALUES ('Aeonax'))" }
      it { is_expected.to eq result }
    end

    context 'as table && alias' do
      let(:structure) { [:users, :u] }
      let(:result) { 'users AS u' }
      it { is_expected.to eq result }
    end
  end
end
