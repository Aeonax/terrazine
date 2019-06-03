# frozen_string_literal: true

require_relative 'helper'

describe 'Compilers::Clause', skip: false do
  context 'WITH' do
    subject { compile }
    let(:clause) { :with }

    context 'array structure' do
      let(:structure) { [:name, { select: :* }] }
      it { is_expected.to eq 'WITH name AS (SELECT * ) ' }
    end

    context 'multi arrays structure' do
      let(:structure) do
        [[:name, { select: :* }],
         [:another_name, { select: :mrgl }]]
      end
      let(:result) { 'WITH name AS (SELECT * ), another_name AS (SELECT mrgl ) ' }
      it { is_expected.to eq result }
    end

    context 'hash structure' do
      let(:structure) do
        { name: { select: :* },
          another_name: { select: :mrgl } }
      end
      let(:result) { 'WITH name AS (SELECT * ), another_name AS (SELECT mrgl ) ' }
      it { is_expected.to eq result }
    end
  end
end
