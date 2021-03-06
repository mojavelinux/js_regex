# encoding: utf-8
# frozen_string_literal: true

require 'spec_helper'

describe JsRegex::Converter::Context do
  let(:context) { described_class.new(//) }

  describe '#initialize' do
    it 'sets added_capturing_groups_after_group to empty Hash with default 0' do
      hash = context.send(:added_capturing_groups_after_group)
      expect(hash).to be_a(Hash)
      expect(hash[99]).to eq(0)
    end

    it 'sets capturing_group_count to 0' do
      expect(context.send(:capturing_group_count)).to eq(0)
    end

    it 'sets named_group_positions to an empty Hash' do
      expect(context.send(:named_group_positions)).to eq({})
    end

    it 'sets warnings to an empty Array' do
      expect(context.send(:warnings)).to eq([])
    end

    it 'sets #case_insensitive_root to true if the regex has the i-flag' do
      context = described_class.new(//i)
      expect(context.case_insensitive_root).to be true
    end

    it 'sets #case_insensitive_root to false if the regex has no i-flag' do
      context = described_class.new(//m)
      expect(context.case_insensitive_root).to be false
    end
  end

  # set context

  describe '#negate_base_set' do
    it 'sets negate_base_set to true' do
      context.instance_variable_set(:@negative_base_set, false)
      context.negate_base_set
      expect(context.negative_base_set).to be true
    end
  end

  describe '#reset_set_context' do
    it 'sets buffered_set_extractions to []' do
      context.instance_variable_set(:@buffered_set_extractions, ['foo'])
      context.reset_set_context
      expect(context.buffered_set_extractions).to eq([])
    end

    it 'sets buffered_set_members to []' do
      context.instance_variable_set(:@buffered_set_members, ['foo'])
      context.reset_set_context
      expect(context.buffered_set_members).to eq([])
    end

    it 'sets negative_base_set to false' do
      context.instance_variable_set(:@negative_base_set, true)
      context.reset_set_context
      expect(context.negative_base_set).to eq(false)
    end
  end

  # group context

  describe '#capture_group' do
    it 'increases capturing_group_count' do
      7.times { context.capture_group }
      expect(context.send(:capturing_group_count)).to eq 7
    end
  end

  describe '#start_atomic_group' do
    it 'sets in_atomic_group to true' do
      context.instance_variable_set(:@in_atomic_group, false)
      context.start_atomic_group
      expect(context.in_atomic_group).to be true
    end
  end

  describe '#end_atomic_group' do
    it 'sets in_atomic_group to false' do
      context.instance_variable_set(:@in_atomic_group, true)
      context.end_atomic_group
      expect(context.in_atomic_group).to be false
    end
  end

  describe '#wrap_in_backrefed_lookahead' do
    before { context.instance_variable_set(:@capturing_group_count, 2) }

    it 'returns the expression wrapped in a backreferenced lookahead' do
      expect(context.wrap_in_backrefed_lookahead('foo'))
        .to eq('(?=(foo))\\3(?:)')
    end

    it 'increases the count of captured groups' do
      expect { context.wrap_in_backrefed_lookahead('foo') }
        .to change { context.send(:capturing_group_count) }.from(2).to(3)
    end

    it 'increases the new_capturing_group_position for any following group' do
      expect(context.new_capturing_group_position(4)).to eq(4)
      context.wrap_in_backrefed_lookahead('foo')
      expect(context.new_capturing_group_position(4)).to eq(5)
    end

    it 'doesnt increase the new_capturing_group_position of preceding groups' do
      expect(context.new_capturing_group_position(1)).to eq(1)
      context.wrap_in_backrefed_lookahead('foo')
      expect(context.new_capturing_group_position(1)).to eq(1)
    end
  end

  describe '#new_capturing_group_position' do
    it 'increments the passed position by count of groups added before it' do
      allow(context).to receive(:added_capturing_groups_after_group)
        .and_return({ 1 => 100, 2 => 100, 3 => 100, 4 => 100, 5 => 100 })
      expect(context.new_capturing_group_position(4)).to eq(304)
    end

    it 'returns the original value if no groups have been added' do
      allow(context).to receive(:added_capturing_groups_after_group)
        .and_return({})
      expect(context.new_capturing_group_position(4)).to eq(4)
    end
  end

  describe '#original_capturing_group_count' do
    it 'returns the current capturing group count minus added ones' do
      allow(context).to receive(:capturing_group_count).and_return(100)
      allow(context).to receive(:total_added_capturing_groups).and_return(10)
      expect(context.original_capturing_group_count).to eq(90)
    end
  end

  describe '#total_added_capturing_groups' do
    it 'returns the sum of all added capturing groups' do
      allow(context).to receive(:added_capturing_groups_after_group)
        .and_return({ 1 => 100, 2 => 100, 3 => 100, 4 => 100, 5 => 100 })
      expect(context.total_added_capturing_groups).to eq(500)
    end

    it 'returns 0 if no groups have been added' do
      allow(context).to receive(:added_capturing_groups_after_group)
        .and_return({})
      expect(context.total_added_capturing_groups).to eq(0)
    end
  end

  describe '#store_named_group_position' do
    it 'bases the position of the group on the previous count of groups' do
      allow(context).to receive(:capturing_group_count).and_return(22)
      context.store_named_group_position('foo')
      expect(context.named_group_positions['foo']).to eq(23)
    end
  end
end
