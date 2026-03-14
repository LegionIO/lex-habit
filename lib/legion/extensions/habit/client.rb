# frozen_string_literal: true

require 'legion/extensions/habit/helpers/constants'
require 'legion/extensions/habit/helpers/action_sequence'
require 'legion/extensions/habit/helpers/habit_store'
require 'legion/extensions/habit/runners/habit'

module Legion
  module Extensions
    module Habit
      class Client
        include Runners::Habit

        attr_reader :habit_store

        def initialize(habit_store: nil, **)
          @habit_store = habit_store || Helpers::HabitStore.new
        end
      end
    end
  end
end
