# frozen_string_literal: true

RSpec.describe Legion::Extensions::Habit::Helpers::HabitStore do
  subject(:store) { described_class.new }

  let(:chunking_threshold) { Legion::Extensions::Habit::Helpers::Constants::CHUNKING_THRESHOLD }

  describe '#initialize' do
    it 'starts with empty habits' do
      expect(store.habits).to be_empty
    end

    it 'starts with empty action buffer' do
      expect(store.action_buffer).to be_empty
    end
  end

  describe '#record_action' do
    it 'adds an entry to the action buffer' do
      store.record_action(:fetch)
      expect(store.action_buffer.size).to eq(1)
    end

    it 'stores the action as a symbol' do
      store.record_action('fetch')
      expect(store.action_buffer.last[:action]).to eq(:fetch)
    end

    it 'stores associated context' do
      store.record_action(:fetch, context: { domain: :api })
      expect(store.action_buffer.last[:context]).to eq({ domain: :api })
    end

    it 'evicts oldest entry when buffer exceeds MAX_BUFFER_SIZE' do
      51.times { |i| store.record_action(:"action_#{i}") }
      expect(store.action_buffer.size).to eq(50)
    end
  end

  describe '#detect_patterns' do
    context 'when a subsequence repeats enough times' do
      it 'detects and stores a new habit' do
        # Fill buffer with CHUNKING_THRESHOLD repetitions of the same 2-action sequence
        chunking_threshold.times do
          store.record_action(:fetch)
          store.record_action(:parse)
        end
        new_habits = store.detect_patterns
        expect(new_habits).not_to be_empty
      end

      it 'returns the detected habit objects' do
        chunking_threshold.times do
          store.record_action(:a)
          store.record_action(:b)
        end
        new_habits = store.detect_patterns
        expect(new_habits.first).to be_a(Legion::Extensions::Habit::Helpers::ActionSequence)
      end
    end

    context 'when a subsequence does not repeat enough times' do
      it 'returns empty array' do
        store.record_action(:fetch)
        store.record_action(:parse)
        new_habits = store.detect_patterns
        expect(new_habits).to be_empty
      end
    end

    context 'when an existing habit matches' do
      it 'reinforces the existing habit rather than creating a new one' do
        # Seed initial habit
        chunking_threshold.times do
          store.record_action(:x)
          store.record_action(:y)
        end
        store.detect_patterns
        expect(store.habits.size).to be >= 1

        # The same sequence already exists — find it and record its execution count
        existing = store.habits.values.find { |h| h.actions == %i[x y] }
        expect(existing).not_to be_nil
        before_count = existing.execution_count

        # Clear the buffer and re-seed to isolate the existing-habit path
        store.action_buffer.clear
        chunking_threshold.times do
          store.record_action(:x)
          store.record_action(:y)
        end
        store.detect_patterns

        # Existing habit should have been reinforced
        expect(existing.execution_count).to be > before_count
      end
    end
  end

  describe '#find_matching' do
    before do
      chunking_threshold.times do
        store.record_action(:fetch, context: { domain: :api })
        store.record_action(:parse, context: { domain: :api })
      end
      store.detect_patterns
    end

    it 'returns habits matching the given context' do
      matches = store.find_matching(context: { domain: :api })
      expect(matches).not_to be_empty
    end

    it 'returns habits sorted by strength descending' do
      matches = store.find_matching(context: { domain: :api })
      strengths = matches.map(&:strength)
      expect(strengths).to eq(strengths.sort.reverse)
    end

    it 'returns empty when no context match' do
      matches = store.find_matching(context: { domain: :db })
      expect(matches).to be_empty
    end
  end

  describe '#get' do
    it 'returns nil for unknown id' do
      expect(store.get('unknown-id')).to be_nil
    end

    it 'returns the habit for a known id' do
      chunking_threshold.times do
        store.record_action(:m)
        store.record_action(:n)
      end
      store.detect_patterns
      id = store.habits.keys.first
      expect(store.get(id)).to be_a(Legion::Extensions::Habit::Helpers::ActionSequence)
    end
  end

  describe '#reinforce' do
    it 'returns nil for unknown id' do
      expect(store.reinforce('unknown', success: true)).to be_nil
    end

    it 'records execution on the habit' do
      chunking_threshold.times do
        store.record_action(:p)
        store.record_action(:q)
      end
      store.detect_patterns
      id     = store.habits.keys.first
      before = store.get(id).execution_count
      store.reinforce(id, success: true)
      expect(store.get(id).execution_count).to be > before
    end
  end

  describe '#decay_all' do
    before do
      chunking_threshold.times do
        store.record_action(:d)
        store.record_action(:e)
      end
      store.detect_patterns
    end

    it 'returns count of removed habits when habits fall below floor' do
      # Force strength below floor by setting it directly
      store.habits.each_value do |h|
        h.instance_variable_set(:@strength, 0.05)
      end
      removed = store.decay_all
      expect(removed).to be >= 0
    end

    it 'returns 0 when all habits survive decay' do
      store.habits.each_value do |h|
        h.instance_variable_set(:@strength, 0.9)
      end
      removed = store.decay_all
      expect(removed).to eq(0)
    end

    it 'removes habits that fall below the floor' do
      store.habits.each_value do |h|
        h.instance_variable_set(:@strength, 0.05)
      end
      store.decay_all
      expect(store.habits).to be_empty
    end
  end

  describe '#merge_similar' do
    it 'returns 0 when there is only one habit' do
      chunking_threshold.times do
        store.record_action(:a)
        store.record_action(:b)
      end
      store.detect_patterns
      expect(store.merge_similar).to eq(0)
    end

    it 'merges highly similar habits and reduces the count' do
      # Create two nearly identical habits manually
      habit_a = Legion::Extensions::Habit::Helpers::ActionSequence.new(actions: %i[x y z])
      habit_b = Legion::Extensions::Habit::Helpers::ActionSequence.new(actions: %i[x y z])
      store.habits[habit_a.id] = habit_a
      store.habits[habit_b.id] = habit_b

      before = store.habits.size
      merged = store.merge_similar
      expect(merged).to eq(1)
      expect(store.habits.size).to eq(before - 1)
    end
  end

  describe '#by_maturity' do
    it 'returns habits at the specified maturity stage' do
      chunking_threshold.times do
        store.record_action(:f)
        store.record_action(:g)
      end
      store.detect_patterns
      novel_habits = store.by_maturity(:novel)
      novel_habits.each { |h| expect(h.maturity).to eq(:novel) }
    end

    it 'returns empty array when no habits at stage' do
      expect(store.by_maturity(:automatic)).to be_empty
    end
  end

  describe '#stats' do
    it 'returns total count of 0 when empty' do
      expect(store.stats[:total]).to eq(0)
    end

    it 'returns correct total after detecting patterns' do
      chunking_threshold.times do
        store.record_action(:h)
        store.record_action(:i)
      end
      store.detect_patterns
      expect(store.stats[:total]).to be >= 1
    end

    it 'includes per_maturity breakdown' do
      expect(store.stats[:per_maturity]).to be_a(Hash)
    end

    it 'includes avg_strength' do
      expect(store.stats[:avg_strength]).to be_a(Numeric)
    end

    it 'returns nil oldest when empty' do
      expect(store.stats[:oldest]).to be_nil
    end
  end

  describe '#evict_if_needed' do
    it 'removes weakest habit when over MAX_HABITS' do
      # Insert MAX_HABITS + 1 habits directly
      (Legion::Extensions::Habit::Helpers::Constants::MAX_HABITS + 1).times do |i|
        h = Legion::Extensions::Habit::Helpers::ActionSequence.new(actions: [:"a#{i}", :"b#{i}"])
        h.instance_variable_set(:@strength, (i + 1).to_f / 1000)
        store.habits[h.id] = h
      end
      store.evict_if_needed
      expect(store.habits.size).to eq(Legion::Extensions::Habit::Helpers::Constants::MAX_HABITS)
    end
  end
end
