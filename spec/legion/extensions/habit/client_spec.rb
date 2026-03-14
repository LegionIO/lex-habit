# frozen_string_literal: true

require 'legion/extensions/habit/client'

RSpec.describe Legion::Extensions::Habit::Client do
  describe '#initialize' do
    it 'creates a default HabitStore when none provided' do
      client = described_class.new
      expect(client.habit_store).to be_a(Legion::Extensions::Habit::Helpers::HabitStore)
    end

    it 'uses an injected habit_store' do
      store  = Legion::Extensions::Habit::Helpers::HabitStore.new
      client = described_class.new(habit_store: store)
      expect(client.habit_store).to be(store)
    end
  end

  describe 'runner methods' do
    let(:client) { described_class.new }

    it 'responds to #observe_action' do
      expect(client).to respond_to(:observe_action)
    end

    it 'responds to #suggest_habit' do
      expect(client).to respond_to(:suggest_habit)
    end

    it 'responds to #execute_habit' do
      expect(client).to respond_to(:execute_habit)
    end

    it 'responds to #decay_habits' do
      expect(client).to respond_to(:decay_habits)
    end

    it 'responds to #merge_habits' do
      expect(client).to respond_to(:merge_habits)
    end

    it 'responds to #habit_stats' do
      expect(client).to respond_to(:habit_stats)
    end

    it 'responds to #habit_repertoire' do
      expect(client).to respond_to(:habit_repertoire)
    end
  end
end
