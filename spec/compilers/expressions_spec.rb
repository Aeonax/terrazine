# frozen_string_literal: true

# require_relative 'helper'
require_relative '../spec_helper'

describe 'Compilers::Expression' do
  subject { Terrazine::Compiler.compile_expressions(structure) }

  context 'true' do
    let(:structure) { true }
    let(:result) { '*' }
    it { is_expected.to eq result }
  end

  context 'Array' do
    context 'with fields' do
      let(:structure) { [:some, [:name, :role, [true]]] }
      let(:result) { 'some, name, role, *' }
      it { is_expected.to eq result }
    end

    context 'as operator' do
      let(:structure) { [:_count, :id] }
      let(:result) { 'COUNT(id)' }
      it { is_expected.to eq result }
    end
  end

  context 'Hash' do
    context 'as sub query' do
      let(:structure) { { select: true } }
      let(:result) { '(SELECT * )' }
      it { is_expected.to eq result }
    end

    context 'as alias' do
      let(:structure) { { _name: :full_name } }
      let(:result) { 'full_name AS name' }
      it { is_expected.to eq result }
    end

    context 'as table with columns' do
      let(:structure) { { u: :name, f: :content } }
      let(:result) { 'u.name, f.content' }
      it { is_expected.to eq result }
    end
  end

  context 'Text' do
    let(:structure) { 'some text that you paste as it is' }
    let(:result) { 'some text that you paste as it is' }
    it { is_expected.to eq result }
  end

  context 'Symbol' do
    let(:structure) { :name }
    let(:result) { 'name' }
    it { is_expected.to eq result }
  end

  context 'Constructor' do
    let(:structure) { init_constructor(select: true) }
    let(:result) { '(SELECT * )' }
    it { is_expected.to eq result }
  end
end
