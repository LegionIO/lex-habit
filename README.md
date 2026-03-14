# lex-habit

Procedural learning and skill acquisition for the LegionIO cognitive architecture.

Models the basal ganglia's procedural learning system: repeated action sequences become chunked into "habits" that execute automatically with decreasing cognitive overhead.

## Installation

```ruby
gem 'legion-extensions-habit'
```

## Usage

```ruby
client = Legion::Extensions::Habit::Client.new

# Record actions as they occur
client.observe_action(action: :fetch_data, context: { domain: :api })
client.observe_action(action: :parse_response, context: { domain: :api })
client.observe_action(action: :cache_result, context: { domain: :api })

# Suggest a learned habit for the current context
result = client.suggest_habit(context: { domain: :api })
puts result[:suggestion]
puts result[:cognitive_savings]

# Execute a known habit
client.execute_habit(id: habit_id, success: true)

# Maintenance
client.decay_habits
client.merge_habits
puts client.habit_stats
```

## Architecture

Habits mature through five stages as they are repeated:
- **novel**: First encounter, full cognitive load (1.0)
- **learning**: Beginning to recognize the pattern (0.8)
- **practiced**: Reliable but still deliberate (0.5)
- **habitual**: Mostly automatic (0.2)
- **automatic**: Fully proceduralized, minimal overhead (0.05)

## License

MIT License. Copyright 2026 Matthew Iverson.
