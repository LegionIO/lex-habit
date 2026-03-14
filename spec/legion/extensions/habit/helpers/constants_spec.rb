# frozen_string_literal: true

RSpec.describe Legion::Extensions::Habit::Helpers::Constants do
  describe 'MATURITY_STAGES' do
    it 'has exactly 5 stages' do
      expect(described_class::MATURITY_STAGES.size).to eq(5)
    end

    it 'includes all expected stages' do
      expect(described_class::MATURITY_STAGES).to include(:novel)
      expect(described_class::MATURITY_STAGES).to include(:learning)
      expect(described_class::MATURITY_STAGES).to include(:practiced)
      expect(described_class::MATURITY_STAGES).to include(:habitual)
      expect(described_class::MATURITY_STAGES).to include(:automatic)
    end

    it 'is ordered from least to most mature' do
      stages = described_class::MATURITY_STAGES
      expect(stages.first).to eq(:novel)
      expect(stages.last).to eq(:automatic)
    end
  end

  describe 'MATURITY_THRESHOLDS' do
    it 'has a threshold for each maturity stage' do
      described_class::MATURITY_STAGES.each do |stage|
        expect(described_class::MATURITY_THRESHOLDS).to have_key(stage)
      end
    end

    it 'thresholds increase with maturity' do
      stages = described_class::MATURITY_STAGES
      thresholds = stages.map { |s| described_class::MATURITY_THRESHOLDS[s] }
      expect(thresholds).to eq(thresholds.sort)
    end

    it 'novel starts at 0' do
      expect(described_class::MATURITY_THRESHOLDS[:novel]).to eq(0)
    end
  end

  describe 'COGNITIVE_COST' do
    it 'has a cost for each maturity stage' do
      described_class::MATURITY_STAGES.each do |stage|
        expect(described_class::COGNITIVE_COST).to have_key(stage)
      end
    end

    it 'cognitive cost decreases with maturity' do
      stages = described_class::MATURITY_STAGES
      costs  = stages.map { |s| described_class::COGNITIVE_COST[s] }
      expect(costs).to eq(costs.sort.reverse)
    end

    it 'novel has maximum cognitive cost of 1.0' do
      expect(described_class::COGNITIVE_COST[:novel]).to eq(1.0)
    end

    it 'automatic has minimum cognitive cost' do
      expect(described_class::COGNITIVE_COST[:automatic]).to be < described_class::COGNITIVE_COST[:habitual]
    end
  end

  describe 'numeric constants' do
    it 'REINFORCEMENT_RATE is positive' do
      expect(described_class::REINFORCEMENT_RATE).to be > 0
    end

    it 'DECAY_RATE is positive' do
      expect(described_class::DECAY_RATE).to be > 0
    end

    it 'MIN_SEQUENCE_LENGTH is at least 2' do
      expect(described_class::MIN_SEQUENCE_LENGTH).to be >= 2
    end

    it 'MAX_SEQUENCE_LENGTH is greater than MIN_SEQUENCE_LENGTH' do
      expect(described_class::MAX_SEQUENCE_LENGTH).to be > described_class::MIN_SEQUENCE_LENGTH
    end

    it 'MAX_HABITS is a positive integer' do
      expect(described_class::MAX_HABITS).to be > 0
    end

    it 'SIMILARITY_THRESHOLD is between 0 and 1' do
      expect(described_class::SIMILARITY_THRESHOLD).to be_between(0.0, 1.0)
    end

    it 'CHUNKING_THRESHOLD is a positive integer' do
      expect(described_class::CHUNKING_THRESHOLD).to be > 0
    end

    it 'HABIT_STRENGTH_FLOOR is positive' do
      expect(described_class::HABIT_STRENGTH_FLOOR).to be > 0
    end
  end

  describe 'CONTEXT_DIMENSIONS' do
    it 'includes :domain' do
      expect(described_class::CONTEXT_DIMENSIONS).to include(:domain)
    end

    it 'includes :mood' do
      expect(described_class::CONTEXT_DIMENSIONS).to include(:mood)
    end

    it 'includes :time_of_day' do
      expect(described_class::CONTEXT_DIMENSIONS).to include(:time_of_day)
    end

    it 'includes :trigger' do
      expect(described_class::CONTEXT_DIMENSIONS).to include(:trigger)
    end
  end
end
