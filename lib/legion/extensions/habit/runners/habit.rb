# frozen_string_literal: true

module Legion
  module Extensions
    module Habit
      module Runners
        module Habit
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def observe_action(action:, context: {}, **)
            Legion::Logging.debug "[habit] observe_action: action=#{action} context=#{context}"
            habit_store.record_action(action, context: context)
            detected = habit_store.detect_patterns
            Legion::Logging.info "[habit] patterns detected: #{detected.size}" unless detected.empty?
            {
              recorded:            true,
              action:              action,
              new_habits_detected: detected.size,
              habits:              detected.map(&:to_h)
            }
          end

          def suggest_habit(context: {}, **)
            matches = habit_store.find_matching(context: context)
            Legion::Logging.debug "[habit] suggest_habit: context=#{context} matches=#{matches.size}"
            if matches.empty?
              { suggestion: nil, reason: :no_matching_habits }
            else
              best = matches.first
              {
                suggestion:        best.to_h,
                cognitive_savings: 1.0 - best.cognitive_cost,
                alternatives:      matches[1..2]&.map(&:to_h) || []
              }
            end
          end

          def execute_habit(id:, success: true, **)
            habit = habit_store.get(id)
            return { error: :not_found } unless habit

            habit.record_execution(success: success)
            Legion::Logging.debug "[habit] execute_habit: id=#{id} success=#{success} maturity=#{habit.maturity}"
            { executed: true, habit: habit.to_h, cognitive_cost: habit.cognitive_cost }
          end

          def decay_habits(**)
            removed = habit_store.decay_all
            Legion::Logging.debug "[habit] decay_habits: removed=#{removed}"
            { decayed: true, removed_count: removed }
          end

          def merge_habits(**)
            merged = habit_store.merge_similar
            Legion::Logging.debug "[habit] merge_habits: merged=#{merged}"
            { merged_count: merged }
          end

          def habit_stats(**)
            habit_store.stats
          end

          def habit_repertoire(maturity: nil, limit: 20, **)
            habits = maturity ? habit_store.by_maturity(maturity.to_sym) : habit_store.habits.values
            Legion::Logging.debug "[habit] habit_repertoire: maturity=#{maturity} total=#{habits.size}"
            {
              habits: habits.sort_by { |h| -h.strength }.first(limit).map(&:to_h),
              total:  habits.size
            }
          end

          private

          def habit_store
            @habit_store ||= Helpers::HabitStore.new
          end
        end
      end
    end
  end
end
