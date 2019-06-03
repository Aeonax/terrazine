# frozen_string_literal: true

require_relative 'helper'

describe 'Compilers::Clause::Values' do
  subject { compile }
  let(:clause) { :values }

  # advanced tests will be in expressions
  context 'Array' do
    context 'of expressions' do
      let(:structure) { [:name, [:_count], { u: :role }] }
      let(:result) { 'VALUES (name, COUNT(*), u.role) ' }
      it { is_expected.to eq result }
    end

    context 'nested' do
      let(:structure) { [[:name, [:_count]], [{ m: :name }, [:_count]]] }
      let(:result) { 'VALUES (name, COUNT(*)), (m.name, COUNT(*)) ' }
      it { is_expected.to eq result }
    end

    context 'as expression' do
      let(:structure) { [:_count] }
      let(:result) { 'VALUES (COUNT(*)) ' }
      it { is_expected.to eq result }
    end
  end

  context 'Text' do
    context 'raw SQL' do
      let(:structure) { '!(something_1), (something_2)' }
      let(:result) { 'VALUES (something_1), (something_2) ' }
      it { is_expected.to eq result }
    end

    context 'values' do
      let(:structure) { 'Aeonax' }
      let(:result) { "VALUES ('Aeonax') " }
      it { is_expected.to eq result }
    end
  end
end
