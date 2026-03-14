# frozen_string_literal: true

require 'legion/extensions/habit/version'
require 'legion/extensions/habit/helpers/constants'
require 'legion/extensions/habit/helpers/action_sequence'
require 'legion/extensions/habit/helpers/habit_store'
require 'legion/extensions/habit/runners/habit'
require 'legion/extensions/habit/client'

module Legion
  module Extensions
    module Habit
      extend Legion::Extensions::Core if defined?(Legion::Extensions::Core)
    end
  end
end
