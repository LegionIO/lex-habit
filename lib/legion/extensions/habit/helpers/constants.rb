# frozen_string_literal: true

module Legion
  module Extensions
    module Habit
      module Helpers
        module Constants
          MATURITY_STAGES = %i[novel learning practiced habitual automatic].freeze

          MATURITY_THRESHOLDS = {
            novel:     0,
            learning:  3,
            practiced: 10,
            habitual:  25,
            automatic: 50
          }.freeze

          COGNITIVE_COST = {
            novel:     1.0,
            learning:  0.8,
            practiced: 0.5,
            habitual:  0.2,
            automatic: 0.05
          }.freeze

          REINFORCEMENT_RATE   = 0.1
          DECAY_RATE           = 0.02
          MIN_SEQUENCE_LENGTH  = 2
          MAX_SEQUENCE_LENGTH  = 10
          MAX_HABITS           = 200
          SIMILARITY_THRESHOLD = 0.7
          CHUNKING_THRESHOLD   = 5
          HABIT_STRENGTH_FLOOR = 0.1

          CONTEXT_DIMENSIONS = %i[domain mood time_of_day trigger].freeze
        end
      end
    end
  end
end
