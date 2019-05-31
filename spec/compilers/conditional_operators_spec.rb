# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Compilers::Operator' do
  subject { Terrazine::Compiler.compile_operators(structure) }

  context 'Conditional' do
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

      context 'True/False/Nulls' do
        let(:structure) { [:_eq, :u__id, true] }
        let(:result) { 'u.id IS TRUE' }
        it { is_expected.to eq result }
      end

      context 'anything else' do
        let(:structure) { [:_eq, :u__id, 1] }
        let(:result) { 'u.id = 1' }
        it { is_expected.to eq result }
      end
    end

    context 'IS' do
      let(:structure) { [:_is, :u__id, nil] }
      let(:result) { 'u.id IS NULL' }
      it { is_expected.to eq result }
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

    context 'Comparisons' do
      context 'BETWEEN' do
        let(:structure) { [:_between, :u__rating, :m__rating, :f__rating] }
        let(:result) { 'u.rating BETWEEN m.rating AND f.rating' }
        it { is_expected.to eq result }
      end

      # Yeah it may be implemented easier, but I wanna same consistency in tests
      context '>' do
        let(:structure) { [:_more, :u__rating, 10] }
        let(:result) { 'u.rating > 10' }
        it { is_expected.to eq result }
      end

      context '>=' do
        let(:structure) { [:_more_eq, :u__rating, 10] }
        let(:result) { 'u.rating >= 10' }
        it { is_expected.to eq result }
      end

      context '<' do
        let(:structure) { [:_less, :u__rating, 10] }
        let(:result) { 'u.rating < 10' }
        it { is_expected.to eq result }
      end

      context '<=' do
        let(:structure) { [:_less_eq, :u__rating, 10] }
        let(:result) { 'u.rating <= 10' }
        it { is_expected.to eq result }
      end
    end
  end
end
