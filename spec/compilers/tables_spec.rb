# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Compilers::Table' do
  subject { Terrazine::Compiler.compile_tables(structure) }

  # God damn it... everything wrong...-_-
  context 'Array' do
    context 'as sub query' do
      let(:structure) { { values: 'Aeonax' } }
      let(:result) { "(VALUES ('Aeonax') )" }
      it { is_expected.to eq result }
    end

    context 'as table && alias' do
      let(:structure) { [:users, :u] }
      let(:result) { 'users AS u' }
      it { is_expected.to eq result }
    end

    context 'as table && alias && columns' do
      let(:structure) { [{ select: true }, :u, [:column_1, :column_2]] }
      let(:result) { '(SELECT * ) AS u (column_1, column_2)' }
      it { is_expected.to eq result }
    end

    context 'as several tables' do
      let(:structure) { [[:users, :u], { values: 1 }] }
      let(:result) { 'users AS u, (VALUES (1) )' }
      it { is_expected.to eq result }
    end
  end

  context 'Hash' do
    let(:structure) { { values: 1 } }
    let(:result) { '(VALUES (1) )' }
    it { is_expected.to eq result }
  end

  context 'Constructor' do
    let(:structure) { init_constructor(values: 1) }
    let(:result) { '(VALUES (1) )' }
    it { is_expected.to eq result }
  end

  context 'Symbol' do
    let(:structure) { :users }
    let(:result) { 'users' }
    it { is_expected.to eq result }
  end
end
