# frozen_string_literal: true

module Legion
  module Extensions
    module Habit
      module Helpers
        class HabitStore # rubocop:disable Metrics/ClassLength
          include Constants

          MAX_BUFFER_SIZE = 50

          attr_reader :habits, :action_buffer

          def initialize
            @habits        = {}
            @action_buffer = []
          end

          def record_action(action, context: {})
            @action_buffer << { action: action.to_sym, context: context }
            @action_buffer.shift if @action_buffer.size > MAX_BUFFER_SIZE
          end

          def detect_patterns
            new_habits = []
            actions    = @action_buffer.map { |e| e[:action] }
            ctx        = @action_buffer.last&.dig(:context) || {}

            (Constants::MIN_SEQUENCE_LENGTH..Constants::MAX_SEQUENCE_LENGTH).each do |len|
              next if actions.size < len

              process_length(len, actions, ctx, new_habits)
            end

            new_habits
          end

          def find_matching(context: {})
            @habits.values
                   .select { |h| h.matches_context?(context) }
                   .sort_by { |h| -h.strength }
          end

          def get(id)
            @habits[id]
          end

          def reinforce(id, success:)
            habit = @habits[id]
            return unless habit

            habit.record_execution(success: success)
          end

          def decay_all
            removed = 0
            @habits.each do |id, habit|
              unless habit.decay
                @habits.delete(id)
                removed += 1
              end
            end
            removed
          end

          def merge_similar
            merged = 0
            @habits.keys.combination(2).each do |id_a, id_b|
              merged += 1 if merge_pair(id_a, id_b)
            end
            merged
          end

          def by_maturity(stage)
            @habits.values.select { |h| h.maturity == stage }
          end

          def stats
            habits_list  = @habits.values
            per_maturity = Constants::MATURITY_STAGES.to_h { |s| [s, 0] }
            habits_list.each { |h| per_maturity[h.maturity] += 1 }
            avg_strength = habits_list.empty? ? 0.0 : habits_list.sum(&:strength) / habits_list.size
            oldest       = habits_list.min_by(&:created_at)
            { total: habits_list.size, per_maturity: per_maturity, avg_strength: avg_strength, oldest: oldest&.to_h }
          end

          def evict_if_needed
            return unless @habits.size > Constants::MAX_HABITS

            weakest_id = @habits.min_by { |_id, h| h.strength }.first
            @habits.delete(weakest_id)
          end

          private

          def process_length(len, actions, ctx, new_habits)
            count_subsequences(actions, len).each do |subseq, count|
              next if count < Constants::CHUNKING_THRESHOLD

              record_or_reinforce(subseq, count, ctx, new_habits)
            end
          end

          def count_subsequences(actions, len)
            counts = Hash.new(0)
            (0..(actions.size - len)).each { |i| counts[actions[i, len]] += 1 }
            counts
          end

          def record_or_reinforce(subseq, count, ctx, new_habits)
            existing = find_existing_sequence(subseq)
            if existing
              existing.record_execution(success: true)
            else
              create_habit(subseq, count, ctx, new_habits)
            end
          end

          def create_habit(subseq, count, ctx, new_habits)
            habit = ActionSequence.new(actions: subseq, context: ctx)
            (count - 1).times { habit.record_execution(success: true) }
            @habits[habit.id] = habit
            evict_if_needed
            new_habits << habit
          end

          def merge_pair(id_a, id_b)
            habit_a = @habits[id_a]
            habit_b = @habits[id_b]
            return false unless habit_a && habit_b
            return false if habit_a.similarity(habit_b) < Constants::SIMILARITY_THRESHOLD

            @habits.delete(habit_a.strength >= habit_b.strength ? id_b : id_a)
            true
          end

          def find_existing_sequence(actions)
            @habits.values.find { |h| h.actions == actions.map(&:to_sym) }
          end
        end
      end
    end
  end
end
