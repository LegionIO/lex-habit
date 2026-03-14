# lex-habit

Habit formation and detection for LegionIO agents. Part of the LegionIO cognitive architecture extension ecosystem (LEX).

## What It Does

`lex-habit` observes a rolling buffer of agent actions, detects repeated subsequences that exceed a frequency threshold, and promotes them through maturity stages. Mature habits carry lower cognitive cost, reducing the overall processing load on the agent. Provides context-aware habit suggestions and similarity-based habit merging.

Key capabilities:

- **Pattern detection**: sliding-window scan over a 50-entry action buffer for subsequences of length 2..10
- **Maturity stages**: novel -> learning -> practiced -> habitual -> automatic, with decreasing cognitive cost (1.0 down to 0.05)
- **Strength dynamics**: reinforcement on execution (+0.1), decay per tick (-0.02), LRU eviction at 200 habits
- **Context matching**: habit suggestions filtered by CONTEXT_DIMENSIONS (domain, mood, time_of_day, trigger)
- **Habit merging**: pairs with Jaccard similarity >= 0.7 are merged, keeping the stronger habit

## Installation

Add to your Gemfile:

```ruby
gem 'lex-habit'
```

Or install directly:

```
gem install lex-habit
```

## Usage

```ruby
require 'legion/extensions/habit'

client = Legion::Extensions::Habit::Client.new

# Record actions as the agent performs them
client.observe_action(action: :search_web, context: { domain: :research })
client.observe_action(action: :summarize,  context: { domain: :research })
client.observe_action(action: :save_note,  context: { domain: :research })

# After enough repetitions, habits are detected automatically.
# Suggest the best matching habit for the current context:
result = client.suggest_habit(context: { domain: :research })
# => { habit: { id: "...", actions: [:search_web, :summarize, :save_note], ... },
#      cognitive_savings: 0.95 }

# Mark a habit as executed (success or failure):
client.execute_habit(id: result[:habit][:id], success: true)

# Maintenance operations
client.decay_habits   # decay all habit strengths, prune weak ones
client.merge_habits   # merge similar habit pairs

# Stats and inspection
client.habit_stats
client.habit_repertoire(maturity: :habitual, limit: 10)
```

## Runner Methods

| Method | Description |
|---|---|
| `observe_action` | Record an action and detect new habits from the buffer |
| `suggest_habit` | Return the best matching habit for a given context |
| `execute_habit` | Record a habit execution (reinforces or weakens strength) |
| `decay_habits` | Decay all habit strengths and prune those below floor |
| `merge_habits` | Merge pairs of similar habits, keeping the stronger |
| `habit_stats` | Summary statistics (total, per-maturity counts, avg strength) |
| `habit_repertoire` | List habits, optionally filtered by maturity stage |

## Maturity Stages

| Stage | Min Executions | Cognitive Cost |
|---|---|---|
| novel | 0 | 1.0 |
| learning | 3 | 0.8 |
| practiced | 10 | 0.5 |
| habitual | 25 | 0.2 |
| automatic | 50 | 0.05 |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
