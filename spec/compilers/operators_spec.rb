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

  context 'Operators' do
    context 'AND' do
      let(:structure) { [:_and, :u__item, :z__mrgl] }
      let(:result) { 'u.item AND z.mrgl' }
      it { is_expected.to eq result }
    end

    context 'NOT' do
      context 'with single element' do
        let(:structure) { [:_not, [:_and, :u__item, :z__mrgl]] }
        let(:result) { 'NOT u.item AND z.mrgl' }
        it { is_expected.to eq result }
      end

      context 'with several values as !=' do
        let(:structure) { [:_not, :u__item, :z__mrgl] }
        let(:result) { 'NOT u.item = z.mrgl' }
        it { is_expected.to eq result }
      end
    end

    context 'IN' do
      context 'Array' do
        let(:structure) { [:_in, :u__id, [1, 2, 3]] }
        let(:result) { 'u.id IN (1, 2, 3)' }
        it { is_expected.to eq result }
      end

      context 'Sub query' do
        let(:structure) { [:_in, :u__id, init_constructor(select: :*)] }
        let(:result) { 'u.id IN (SELECT * )' }
        it { is_expected.to eq result }
      end

      context 'anything else' do
        let(:structure) { [:_in, :u__id, "'mrgl', 'rgl'"] }
        let(:result) { "u.id IN (#{structure[2]})" }
        it { is_expected.to eq result }
      end
    end

    context '=' do
      context 'Array' do
        let(:structure) { [:_eq, :u__id, [1, 2, 3]] }
        let(:result) { 'u.id IN (1, 2, 3)' }
        it { is_expected.to eq result }
      end

      context 'anything else' do
        let(:structure) { [:_eq, :u__id, true] }
        let(:result) { 'u.id = TRUE' }
        it { is_expected.to eq result }
      end
    end

    context 'IS' do
      let(:structure) { [:_is, :u__id, true] }
      let(:result) { 'u.id IS TRUE' }
      it { is_expected.to eq result }
    end

    context 'BETWEEN' do
      context 'multiple values' do
        let(:structure) { [:_between, :u__rating, :m__rating, :f__rating] }
        let(:result) { 'BETWEEN u.rating AND m.rating AND f.rating' }
        it { is_expected.to eq result }
      end

      context 'any other single value treated as expression' do
        let(:structure) { [:_between, 'u.rating AND 95'] }
        let(:result) { "BETWEEN #{structure[1]}" }
        it { is_expected.to eq result }
      end
    end

    context 'Patterns' do
      context 'LIKE' do
        let(:structure) { [:_like, :u__name, 'Aeonax'] }
        let(:result) { "u.name LIKE 'Aeonax'" }
        it { is_expected.to eq result }
      end
      context 'iLIKE' do
        let(:structure) { [:_ilike, :u__name, { select: :name }] }
        let(:result) { "u.name iLIKE (SELECT name )" }
        it { is_expected.to eq result }
      end
      context '~' do
        let(:structure) { [:_reg, :u__name, '^[a-o]2'] }
        let(:result) { "u.name ~ '^[a-o]2'" }
        it { is_expected.to eq result }
      end
      context '~*' do
        let(:structure) { [:_reg_i, :u__name, '^[a-o]2'] }
        let(:result) { "u.name ~* '^[a-o]2'" }
        it { is_expected.to eq result }
      end
      context '!~' do
        let(:structure) { [:_reg_f, :u__name, '^[a-o]2'] }
        let(:result) { "u.name !~ '^[a-o]2'" }
        it { is_expected.to eq result }
      end
      context '!~*' do
        let(:structure) { [:_reg_fi, :u__name, '^[a-o]2'] }
        let(:result) { "u.name !~* '^[a-o]2'" }
        it { is_expected.to eq result }
      end
    end
  end
end
