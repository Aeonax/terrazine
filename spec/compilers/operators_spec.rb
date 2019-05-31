# frozen_string_literal: true

# require_relative 'helper'
require_relative '../spec_helper'

describe 'Compilers::Operator' do
  subject { Terrazine::Compiler.compile_operators(structure) }

  context 'COUNT with' do
    context 'empty args' do
      let(:structure) { [:_count] }
      let(:result) { 'COUNT(*)' }
      it { is_expected.to eq result }
    end

    context 'column' do
      let(:structure) { [:_count, :name] }
      let(:result) { 'COUNT(name)' }
      it { is_expected.to eq result }
    end

    context 'hash argument' do
      let(:structure) { [:_count, { first_c: :id, second_c: :smth }] }
      let(:result) { 'COUNT(id) AS first_c, COUNT(smth) AS second_c' }
      it { is_expected.to eq result }
    end
  end

  context 'NULLIF' do
    let(:structure) { [:_nullif, { u: :admin }, true] }
    let(:result) { 'NULLIF(u.admin, TRUE)' }
    it { is_expected.to eq result }
  end

  context 'ARRAY' do
    context 'with Subquery' do
      context 'Hash' do
        let(:structure) { [:_array, { select: :* }] }
        let(:result) { 'ARRAY(SELECT * )' }
        it { is_expected.to eq result }
      end

      context 'Constructor' do
        let(:structure) { [:_array, init_constructor(select: :*)] }
        let(:result) { 'ARRAY(SELECT * )' }
        it { is_expected.to eq result }
      end
    end

    context 'expressions' do
      context 'Hash' do
        let(:structure) { [:_array, { u: :name }] }
        let(:result) { 'ARRAY[u.name]' }
        it { is_expected.to eq result }
      end

      context 'not Hash' do
        let(:structure) { [:_array, [:name, true, [:_count]]] }
        let(:result) { 'ARRAY[name, TRUE, COUNT(*)]' }
        it { is_expected.to eq result }
      end

      context 'nested' do
        let(:structure) { [:_array, [[:mrgl, :rgl], [:name, true]]] }
        let(:result) { 'ARRAY[[mrgl, rgl], [name, TRUE]]' }
        it { is_expected.to eq result }
      end

      context 'structure like nested' do
        let(:structure) { [:_array, [[:_count], [:_count, :id]]] }
        let(:result) { 'ARRAY[COUNT(*), COUNT(id)]' }
        it { is_expected.to eq result }
      end
    end
  end

  context 'AVG' do
    let(:structure) { [:_avg, { u: :amount }] }
    let(:result) { 'AVG(u.amount)' }
    it { is_expected.to eq result }
  end

  context 'missing operator' do
    let(:structure) { [:_missing_operator, { u: :name }] }
    let(:result) { 'MISSING_OPERATOR(u.name)' }
    it { is_expected.to eq result }
  end

  context 'JSON_AGG' do
    context 'with sub query' do
      let(:structure) { [:_json_agg, { select: :* }] }
      let(:result) { '(SELECT JSON_AGG(item) FROM (SELECT * ) AS item )' }
      it { is_expected.to eq result }
    end

    context 'single value' do
      let(:structure) { [:_json_agg, :u__item] }
      let(:result) { 'JSON_AGG(u.item)' }
      it { is_expected.to eq result }
    end
  end
end
