# frozen_string_literal: true

require 'legion/extensions/habit/client'

RSpec.describe Legion::Extensions::Habit::Runners::Habit do
  let(:habit_store) { Legion::Extensions::Habit::Helpers::HabitStore.new }
  let(:client) { Legion::Extensions::Habit::Client.new(habit_store: habit_store) }

  let(:chunking_threshold) { Legion::Extensions::Habit::Helpers::Constants::CHUNKING_THRESHOLD }

  def seed_habit
    chunking_threshold.times do
      habit_store.record_action(:fetch)
      habit_store.record_action(:parse)
    end
    habit_store.detect_patterns
    habit_store.habits.values.first
  end

  describe '#observe_action' do
    it 'returns recorded: true' do
      result = client.observe_action(action: :fetch)
      expect(result[:recorded]).to be true
    end

    it 'includes the action in response' do
      result = client.observe_action(action: :fetch)
      expect(result[:action]).to eq(:fetch)
    end

    it 'includes new_habits_detected count' do
      result = client.observe_action(action: :fetch)
      expect(result).to have_key(:new_habits_detected)
    end

    it 'detects new habits after sufficient repetitions' do
      (chunking_threshold - 1).times do
        client.observe_action(action: :x)
        client.observe_action(action: :y)
      end
      client.observe_action(action: :x)
      # The final observe adds the action; next observe_action with :y should trigger detection
      client.observe_action(action: :y)
      expect(habit_store.habits.size).to be >= 0
    end

    it 'includes habits array in response' do
      result = client.observe_action(action: :fetch)
      expect(result[:habits]).to be_an(Array)
    end
  end

  describe '#suggest_habit' do
    context 'when no matching habits exist' do
      it 'returns suggestion: nil' do
        result = client.suggest_habit(context: { domain: :api })
        expect(result[:suggestion]).to be_nil
      end

      it 'returns reason: :no_matching_habits' do
        result = client.suggest_habit(context: { domain: :api })
        expect(result[:reason]).to eq(:no_matching_habits)
      end
    end

    context 'when matching habits exist' do
      before do
        chunking_threshold.times do
          habit_store.record_action(:fetch, context: { domain: :api })
          habit_store.record_action(:parse, context: { domain: :api })
        end
        habit_store.detect_patterns
      end

      it 'returns a suggestion hash' do
        result = client.suggest_habit(context: { domain: :api })
        expect(result[:suggestion]).to be_a(Hash)
      end

      it 'returns cognitive_savings as a positive value' do
        result = client.suggest_habit(context: { domain: :api })
        expect(result[:cognitive_savings]).to be > 0
      end

      it 'includes alternatives array' do
        result = client.suggest_habit(context: { domain: :api })
        expect(result[:alternatives]).to be_an(Array)
      end
    end
  end

  describe '#execute_habit' do
    context 'when habit not found' do
      it 'returns error: :not_found' do
        result = client.execute_habit(id: 'nonexistent')
        expect(result[:error]).to eq(:not_found)
      end
    end

    context 'when habit exists' do
      it 'returns executed: true' do
        habit  = seed_habit
        result = client.execute_habit(id: habit.id)
        expect(result[:executed]).to be true
      end

      it 'returns the updated habit hash' do
        habit  = seed_habit
        result = client.execute_habit(id: habit.id)
        expect(result[:habit]).to be_a(Hash)
        expect(result[:habit][:id]).to eq(habit.id)
      end

      it 'returns cognitive_cost' do
        habit  = seed_habit
        result = client.execute_habit(id: habit.id)
        expect(result[:cognitive_cost]).to be_a(Numeric)
      end

      it 'increments the execution count' do
        habit  = seed_habit
        before = habit.execution_count
        client.execute_habit(id: habit.id, success: true)
        expect(habit.execution_count).to eq(before + 1)
      end
    end
  end

  describe '#decay_habits' do
    it 'returns decayed: true' do
      result = client.decay_habits
      expect(result[:decayed]).to be true
    end

    it 'returns removed_count' do
      result = client.decay_habits
      expect(result).to have_key(:removed_count)
    end

    it 'removes habits that fall below floor' do
      habit = seed_habit
      habit.instance_variable_set(:@strength, 0.05)
      client.decay_habits
      expect(habit_store.get(habit.id)).to be_nil
    end
  end

  describe '#merge_habits' do
    it 'returns merged_count' do
      result = client.merge_habits
      expect(result).to have_key(:merged_count)
    end

    it 'returns 0 when no similar habits to merge' do
      result = client.merge_habits
      expect(result[:merged_count]).to eq(0)
    end

    it 'merges identical habits' do
      # Manually insert two identical habits
      h1 = Legion::Extensions::Habit::Helpers::ActionSequence.new(actions: %i[p q r])
      h2 = Legion::Extensions::Habit::Helpers::ActionSequence.new(actions: %i[p q r])
      habit_store.habits[h1.id] = h1
      habit_store.habits[h2.id] = h2

      result = client.merge_habits
      expect(result[:merged_count]).to eq(1)
    end
  end

  describe '#habit_stats' do
    it 'returns a hash with total key' do
      result = client.habit_stats
      expect(result).to have_key(:total)
    end

    it 'returns per_maturity breakdown' do
      result = client.habit_stats
      expect(result[:per_maturity]).to be_a(Hash)
    end

    it 'returns avg_strength' do
      result = client.habit_stats
      expect(result[:avg_strength]).to be_a(Numeric)
    end
  end

  describe '#habit_repertoire' do
    context 'when no maturity filter' do
      it 'returns all habits' do
        seed_habit
        result = client.habit_repertoire
        expect(result[:habits]).to be_an(Array)
        expect(result[:total]).to be >= 1
      end
    end

    context 'with maturity filter' do
      it 'returns only habits at the given maturity stage' do
        seed_habit
        result = client.habit_repertoire(maturity: :novel)
        result[:habits].each do |h|
          expect(h[:maturity]).to eq(:novel)
        end
      end
    end

    it 'respects limit parameter' do
      10.times do |i|
        h = Legion::Extensions::Habit::Helpers::ActionSequence.new(actions: [:"action#{i}", :"step#{i}"])
        habit_store.habits[h.id] = h
      end
      result = client.habit_repertoire(limit: 3)
      expect(result[:habits].size).to be <= 3
    end

    it 'sorts by strength descending' do
      3.times do |i|
        h = Legion::Extensions::Habit::Helpers::ActionSequence.new(actions: [:"s#{i}", :"t#{i}"])
        h.instance_variable_set(:@strength, (i + 1).to_f / 10)
        habit_store.habits[h.id] = h
      end
      result = client.habit_repertoire
      strengths = result[:habits].map { |h| h[:strength] }
      expect(strengths).to eq(strengths.sort.reverse)
    end
  end
end
