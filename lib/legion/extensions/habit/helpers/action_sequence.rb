# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Habit
      module Helpers
        class ActionSequence
          include Constants

          attr_reader :id, :actions, :context, :execution_count, :success_count,
                      :strength, :maturity, :last_executed, :created_at

          def initialize(actions:, context: {})
            @id              = SecureRandom.uuid
            @actions         = actions.map(&:to_sym)
            @context         = context
            @execution_count = 0
            @success_count   = 0
            @strength        = 0.3
            @maturity        = :novel
            @last_executed   = nil
            @created_at      = Time.now.utc
          end

          def record_execution(success:)
            @execution_count += 1
            @success_count   += 1 if success
            @last_executed    = Time.now.utc

            @strength = if success
                          [@strength + Constants::REINFORCEMENT_RATE, 1.0].min
                        else
                          [@strength - Constants::REINFORCEMENT_RATE, 0.0].max
                        end

            update_maturity
          end

          def cognitive_cost
            Constants::COGNITIVE_COST[@maturity]
          end

          def success_rate
            return 0.0 if @execution_count.zero?

            @success_count.to_f / @execution_count
          end

          def matches_context?(ctx)
            return true if ctx.empty?

            relevant = Constants::CONTEXT_DIMENSIONS.select { |d| @context.key?(d) || ctx.key?(d) }
            return true if relevant.empty?

            matches = relevant.count { |d| @context[d] == ctx[d] }
            matches.to_f / relevant.size >= 0.5
          end

          def decay
            @strength -= Constants::DECAY_RATE
            @strength >= Constants::HABIT_STRENGTH_FLOOR
          end

          def mature?
            @maturity == :habitual || @maturity == :automatic
          end

          def stale?(threshold = 3600)
            return true if @last_executed.nil?

            (Time.now.utc - @last_executed) > threshold
          end

          def similarity(other)
            set_a = @actions.uniq
            set_b = other.actions.uniq
            return 0.0 if set_a.empty? && set_b.empty?

            intersection = (set_a & set_b).size
            union        = (set_a | set_b).size
            return 0.0 if union.zero?

            intersection.to_f / union
          end

          def to_h
            {
              id:              @id,
              actions:         @actions,
              context:         @context,
              execution_count: @execution_count,
              success_count:   @success_count,
              strength:        @strength,
              maturity:        @maturity,
              cognitive_cost:  cognitive_cost,
              success_rate:    success_rate,
              last_executed:   @last_executed,
              created_at:      @created_at
            }
          end

          private

          def update_maturity
            new_stage = Constants::MATURITY_STAGES.reverse.find do |stage|
              @execution_count >= Constants::MATURITY_THRESHOLDS[stage]
            end
            @maturity = new_stage || :novel
          end
        end
      end
    end
  end
end
