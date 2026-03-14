# frozen_string_literal: true

RSpec.describe Legion::Extensions::Habit::Helpers::ActionSequence do
  let(:actions) { %i[fetch parse cache] }
  let(:context) { { domain: :api, mood: :neutral } }
  let(:sequence) { described_class.new(actions: actions, context: context) }

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(sequence.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores actions as symbols' do
      expect(sequence.actions).to eq(%i[fetch parse cache])
    end

    it 'stores context' do
      expect(sequence.context).to eq(context)
    end

    it 'starts with zero execution count' do
      expect(sequence.execution_count).to eq(0)
    end

    it 'starts with zero success count' do
      expect(sequence.success_count).to eq(0)
    end

    it 'starts with strength 0.3' do
      expect(sequence.strength).to eq(0.3)
    end

    it 'starts at :novel maturity' do
      expect(sequence.maturity).to eq(:novel)
    end

    it 'has nil last_executed' do
      expect(sequence.last_executed).to be_nil
    end

    it 'records created_at' do
      expect(sequence.created_at).to be_a(Time)
    end

    it 'converts string actions to symbols' do
      seq = described_class.new(actions: %w[fetch parse])
      expect(seq.actions).to eq(%i[fetch parse])
    end
  end

  describe '#record_execution' do
    context 'when success: true' do
      it 'increments execution_count' do
        sequence.record_execution(success: true)
        expect(sequence.execution_count).to eq(1)
      end

      it 'increments success_count' do
        sequence.record_execution(success: true)
        expect(sequence.success_count).to eq(1)
      end

      it 'increases strength' do
        before = sequence.strength
        sequence.record_execution(success: true)
        expect(sequence.strength).to be > before
      end

      it 'sets last_executed' do
        sequence.record_execution(success: true)
        expect(sequence.last_executed).to be_a(Time)
      end
    end

    context 'when success: false' do
      it 'increments execution_count' do
        sequence.record_execution(success: false)
        expect(sequence.execution_count).to eq(1)
      end

      it 'does not increment success_count' do
        sequence.record_execution(success: false)
        expect(sequence.success_count).to eq(0)
      end

      it 'decreases strength' do
        before = sequence.strength
        sequence.record_execution(success: false)
        expect(sequence.strength).to be < before
      end
    end

    it 'does not exceed strength 1.0' do
      20.times { sequence.record_execution(success: true) }
      expect(sequence.strength).to be <= 1.0
    end

    it 'does not go below strength 0.0' do
      20.times { sequence.record_execution(success: false) }
      expect(sequence.strength).to be >= 0.0
    end
  end

  describe '#maturity progression' do
    it 'advances to :learning after enough executions' do
      threshold = Legion::Extensions::Habit::Helpers::Constants::MATURITY_THRESHOLDS[:learning]
      threshold.times { sequence.record_execution(success: true) }
      expect(sequence.maturity).to eq(:learning)
    end

    it 'advances to :practiced after enough executions' do
      threshold = Legion::Extensions::Habit::Helpers::Constants::MATURITY_THRESHOLDS[:practiced]
      threshold.times { sequence.record_execution(success: true) }
      expect(sequence.maturity).to eq(:practiced)
    end

    it 'advances to :habitual after enough executions' do
      threshold = Legion::Extensions::Habit::Helpers::Constants::MATURITY_THRESHOLDS[:habitual]
      threshold.times { sequence.record_execution(success: true) }
      expect(sequence.maturity).to eq(:habitual)
    end

    it 'advances to :automatic after enough executions' do
      threshold = Legion::Extensions::Habit::Helpers::Constants::MATURITY_THRESHOLDS[:automatic]
      threshold.times { sequence.record_execution(success: true) }
      expect(sequence.maturity).to eq(:automatic)
    end
  end

  describe '#cognitive_cost' do
    it 'returns the cost for the current maturity stage' do
      cost = Legion::Extensions::Habit::Helpers::Constants::COGNITIVE_COST[:novel]
      expect(sequence.cognitive_cost).to eq(cost)
    end

    it 'decreases as maturity increases' do
      novel_cost = sequence.cognitive_cost
      threshold  = Legion::Extensions::Habit::Helpers::Constants::MATURITY_THRESHOLDS[:automatic]
      threshold.times { sequence.record_execution(success: true) }
      expect(sequence.cognitive_cost).to be < novel_cost
    end
  end

  describe '#success_rate' do
    it 'returns 0.0 when no executions' do
      expect(sequence.success_rate).to eq(0.0)
    end

    it 'returns 1.0 when all executions are successful' do
      3.times { sequence.record_execution(success: true) }
      expect(sequence.success_rate).to eq(1.0)
    end

    it 'returns partial rate for mixed executions' do
      sequence.record_execution(success: true)
      sequence.record_execution(success: false)
      expect(sequence.success_rate).to eq(0.5)
    end
  end

  describe '#matches_context?' do
    it 'returns true for empty context' do
      expect(sequence.matches_context?({})).to be true
    end

    it 'returns true when majority of dimensions match' do
      expect(sequence.matches_context?({ domain: :api, mood: :neutral })).to be true
    end

    it 'returns false when majority of dimensions do not match' do
      expect(sequence.matches_context?({ domain: :db, mood: :stressed })).to be false
    end

    it 'returns true for partial match meeting 50% threshold' do
      # context has domain: :api, mood: :neutral
      # querying with domain: :api only — 100% match on stored dims
      expect(sequence.matches_context?({ domain: :api })).to be true
    end
  end

  describe '#decay' do
    it 'reduces strength by DECAY_RATE' do
      before = sequence.strength
      sequence.decay
      expect(sequence.strength).to be_within(0.001).of(before - Legion::Extensions::Habit::Helpers::Constants::DECAY_RATE)
    end

    it 'returns true when strength is above floor' do
      expect(sequence.decay).to be true
    end

    it 'returns false when strength falls to or below floor' do
      floor = Legion::Extensions::Habit::Helpers::Constants::HABIT_STRENGTH_FLOOR
      # Set strength just below floor + decay_rate so one decay pushes it under
      rate = Legion::Extensions::Habit::Helpers::Constants::DECAY_RATE
      seq  = described_class.new(actions: %i[a b])
      seq.instance_variable_set(:@strength, floor + (rate * 0.5))
      expect(seq.decay).to be false
    end
  end

  describe '#mature?' do
    it 'returns false for :novel stage' do
      expect(sequence.mature?).to be false
    end

    it 'returns true for :habitual stage' do
      threshold = Legion::Extensions::Habit::Helpers::Constants::MATURITY_THRESHOLDS[:habitual]
      threshold.times { sequence.record_execution(success: true) }
      expect(sequence.mature?).to be true
    end

    it 'returns true for :automatic stage' do
      threshold = Legion::Extensions::Habit::Helpers::Constants::MATURITY_THRESHOLDS[:automatic]
      threshold.times { sequence.record_execution(success: true) }
      expect(sequence.mature?).to be true
    end
  end

  describe '#stale?' do
    it 'returns true when never executed' do
      expect(sequence.stale?).to be true
    end

    it 'returns false when executed recently' do
      sequence.record_execution(success: true)
      expect(sequence.stale?(3600)).to be false
    end

    it 'returns true when last executed beyond threshold' do
      sequence.record_execution(success: true)
      sequence.instance_variable_set(:@last_executed, Time.now.utc - 7200)
      expect(sequence.stale?(3600)).to be true
    end
  end

  describe '#similarity' do
    it 'returns 1.0 for identical sequences' do
      other = described_class.new(actions: actions)
      expect(sequence.similarity(other)).to eq(1.0)
    end

    it 'returns 0.0 for completely different sequences' do
      other = described_class.new(actions: %i[open write close])
      expect(sequence.similarity(other)).to eq(0.0)
    end

    it 'returns a partial score for overlapping sequences' do
      other = described_class.new(actions: %i[fetch transform store])
      score = sequence.similarity(other)
      expect(score).to be > 0.0
      expect(score).to be < 1.0
    end
  end

  describe '#to_h' do
    it 'returns a hash with all expected keys' do
      h = sequence.to_h
      expect(h).to have_key(:id)
      expect(h).to have_key(:actions)
      expect(h).to have_key(:context)
      expect(h).to have_key(:execution_count)
      expect(h).to have_key(:success_count)
      expect(h).to have_key(:strength)
      expect(h).to have_key(:maturity)
      expect(h).to have_key(:cognitive_cost)
      expect(h).to have_key(:success_rate)
      expect(h).to have_key(:last_executed)
      expect(h).to have_key(:created_at)
    end

    it 'includes the correct maturity' do
      expect(sequence.to_h[:maturity]).to eq(:novel)
    end
  end
end
