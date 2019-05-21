# frozen_string_literal: true

# require_relative 'helper'
require_relative '../spec_helper'

describe 'Compilers::Condition' do
  subject { Terrazine::Compiler.compile_conditions(structure) }

  context 'Array' do
    context 'as parenthes' do
      let(:structure) { [[:_and, 'u.id = r.user_id', 'm.user_id = u.id']] }
      let(:result) { '(u.id = r.user_id AND m.user_id = u.id)' }
      it { is_expected.to eq result }
    end

    context 'as operator' do
      let(:structure) { [:_eq, :u__id, :m__user_id] }
      let(:result) { 'u.id = m.user_id' }
      it { is_expected.to eq result }
    end
  end

  context 'Hash' do
    context 'as sub query' do
      let(:structure) { { select: :* } }
      let(:result) { '(SELECT * )' }
      it { is_expected.to eq result }
    end

    context 'as equality' do
      let(:structure) { { u__id: :m__user_id, m__id: :f__m_id } }
      let(:result) { 'u.id = m.user_id AND m.id = f.m_id' }
      it { is_expected.to eq result }
    end

    # context 'as array of equalities?' do
    #   let(:structure) { { u__id: [:m__user_id, :f__user_id] } }
    #   let(:result) { 'u.id = m.user_id AND u.id = f.user_id' }
    #   it { is_expected.to eq result }
    # end

    context 'as in statement' do
      let(:structure) { { u__id: [:m__user_id, :f__user_id] } }
      let(:result) { 'u.id IN (m.user_id, f.user_id)' }
      it { is_expected.to eq result }
    end
  end

  context 'String' do
    let(:structure) { 'true' }
    let(:result) { structure }
    it { is_expected.to eq result }
  end

  # context 'as sub query interpolation' do
  #   let(:structure) { ['id IN ?', { select: :* }] }
  #   let(:result) { 'id IN (SELECT * )' }
  #   it { is_expected.to eq result }
  # end

  # context 'as params interpolation' do
  #   let(:structure) { ['name = ?', 'Aeonax'] }
  #   let(:result) { ['name = $1', 'Aeonax'] }
  #   it { is_expected.to eq result }
  # end
end
