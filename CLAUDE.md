# lex-habit

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-habit`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::Habit`

## Purpose

Habit formation and detection through action sequence pattern recognition. Observes a rolling buffer of agent actions, automatically identifies repeated subsequences that exceed a frequency threshold, and promotes them through maturity stages with decreasing cognitive cost. Provides context-aware habit suggestions and sequence similarity-based merging.

## Gem Info

- **Require path**: `legion/extensions/habit`
- **Ruby**: >= 3.4
- **License**: MIT
- **Registers with**: `Legion::Extensions::Core`

## File Structure

```
lib/legion/extensions/habit/
  version.rb
  helpers/
    constants.rb            # Maturity stages, thresholds, cognitive cost table
    action_sequence.rb      # Habit value object (ActionSequence)
    habit_store.rb          # Rolling buffer + pattern detection + storage
  runners/
    habit.rb                # Runner module
  client.rb

spec/
  legion/extensions/habit/
    helpers/
      constants_spec.rb
      action_sequence_spec.rb
      habit_store_spec.rb
    runners/habit_spec.rb
    client_spec.rb
  spec_helper.rb
```

## Key Constants

```ruby
MATURITY_STAGES    = %i[novel learning practiced habitual automatic]
MATURITY_THRESHOLDS = { novel: 0, learning: 3, practiced: 10, habitual: 25, automatic: 50 }

COGNITIVE_COST = {
  novel: 1.0, learning: 0.8, practiced: 0.5, habitual: 0.2, automatic: 0.05
}

REINFORCEMENT_RATE   = 0.1    # strength delta per successful execution
DECAY_RATE           = 0.02   # strength lost per decay tick
MIN_SEQUENCE_LENGTH  = 2
MAX_SEQUENCE_LENGTH  = 10
MAX_HABITS           = 200    # LRU eviction by strength when exceeded
SIMILARITY_THRESHOLD = 0.7    # Jaccard overlap threshold for merging
CHUNKING_THRESHOLD   = 5      # minimum occurrences in buffer to create habit
HABIT_STRENGTH_FLOOR = 0.1    # habits below this are removed on decay

CONTEXT_DIMENSIONS = %i[domain mood time_of_day trigger]
```

## Helpers

### `Helpers::ActionSequence` (class)

Value object representing one recognized habit.

| Attribute | Type | Description |
|---|---|---|
| `id` | String (UUID) | unique identifier |
| `actions` | Array<Symbol> | the action sequence |
| `context` | Hash | context at time of formation |
| `execution_count` | Integer | total executions |
| `success_count` | Integer | successful executions |
| `strength` | Float (0..1) | current habit strength |
| `maturity` | Symbol | current maturity stage |

Key methods:
- `record_execution(success:)` — updates counts, adjusts strength, advances maturity
- `cognitive_cost` — returns cost from COGNITIVE_COST table for current maturity
- `success_rate` — success_count / execution_count
- `matches_context?(ctx)` — 50%+ of shared context dimensions must match
- `decay` — subtracts DECAY_RATE, returns false if below floor
- `mature?` — maturity is :habitual or :automatic
- `stale?(threshold)` — true if last_executed is nil or older than threshold seconds
- `similarity(other)` — Jaccard coefficient of action sets

### `Helpers::HabitStore` (class)

Rolling action buffer (50 entries) and habit registry.

| Method | Description |
|---|---|
| `record_action(action, context:)` | appends to buffer, shifts oldest if at capacity |
| `detect_patterns` | scans buffer for repeated subsequences >= CHUNKING_THRESHOLD |
| `find_matching(context:)` | returns habits sorted by strength that match context |
| `get(id)` | retrieve by id |
| `reinforce(id, success:)` | delegate to habit's record_execution |
| `decay_all` | decays all habits, removes those below floor; returns count removed |
| `merge_similar` | combines pairs above SIMILARITY_THRESHOLD, keeps stronger; returns count merged |
| `by_maturity(stage)` | filter by maturity stage |
| `stats` | total, per_maturity counts, avg_strength, oldest habit |
| `evict_if_needed` | removes weakest habit when over MAX_HABITS |

## Runners

Module: `Legion::Extensions::Habit::Runners::Habit`

Private state: `@habit_store` (memoized `HabitStore` instance).

| Runner Method | Parameters | Description |
|---|---|---|
| `observe_action` | `action:, context: {}` | Record action, detect new habits from buffer |
| `suggest_habit` | `context: {}` | Best matching habit for context + cognitive_savings |
| `execute_habit` | `id:, success:` | Record execution, return cognitive_cost |
| `decay_habits` | (none) | Decay and prune weak habits |
| `merge_habits` | (none) | Merge similar habits |
| `habit_stats` | (none) | Summary statistics |
| `habit_repertoire` | `maturity:, limit: 20` | List habits optionally filtered by maturity |

## Integration Points

- **lex-tick**: habit suggestions from `suggest_habit` can be surfaced in the `action_selection` phase. Lower cognitive cost habits reduce overall `cognitive_load` reading consumed by `lex-homeostasis`.
- **lex-homeostasis**: `cognitive_load` observation in `regulate` comes from tick elapsed/budget ratio; reducing it via habits is the indirect benefit.
- **lex-metacognition**: `Habit` is listed under `:cognition` capability category.
- **lex-conditioner / lex-transformer**: habit IDs or action sequences can be embedded in task payloads.

## Development Notes

- Pattern detection uses a sliding window over `MIN_SEQUENCE_LENGTH..MAX_SEQUENCE_LENGTH` and counts all subsequences via `count_subsequences`.
- A habit is only created when a subsequence appears `CHUNKING_THRESHOLD` (5) or more times. On subsequent detections, the existing habit is reinforced rather than duplicated.
- `merge_similar` uses pairwise combination (`Array#combination(2)`) over all habit IDs — O(n^2). For 200 habits this is 19,900 pairs.
- Context matching uses `CONTEXT_DIMENSIONS` as the declared dimension set; dimensions not in that list are ignored.
- `stale?` checks `last_executed` but decay removes the habit only when strength drops below `HABIT_STRENGTH_FLOOR` — staleness is not independently enforced.
- No actor defined; decay and merge are triggered manually via runner methods.
