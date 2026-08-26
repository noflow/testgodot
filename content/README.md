# Global content

Character-owned quests, conversations, texts, and outcomes live inside that
character's `.character` package. Content involving locations, institutions, or
unnamed service NPCs lives here.

- `opening/global_quests.json` contains the opening institutional and tutorial quests.
- `opening/global_conversations.json` contains their service conversations.
- `opening/opening_week.json` maps Tuesday through Sunday across all seven blocks.
- `world/all_locations.json` is the canonical city registry for districts, travel destinations, homes, rooms, access, services, and legacy location aliases.
- `world/transportation.json` defines travel modes, routes, time, cost, and delays.
- `systems/education.json` defines Westshore programs, courses, schedules, and grading.
- `systems/character_creation.json` defines appearance choices, traits, values, hobbies, archetypes, and validation rules.
- `systems/home_interactions.json` defines atomic bedroom, bathroom, kitchen, and laundry actions.
- `systems/city_interactions.json` connects city rooms to conversations and atomic institutional, employment, and fitness activities.
- `systems/phone.json` defines reusable phone apps—including Jobs—scheduling types, and relationship level labels.
- `systems/employment.json` defines jobs, requirements, interviews, work approaches, performance, raises, and promotions.
- `systems/repeatable_activities.json` defines routine actions and simulation effects.
- `systems/economy.json` defines accounts, budgets, recurring bills, debt, and income.
- `systems/inventory.json` defines containers, item rules, and starting loadouts.
- `systems/clothing.json` defines wardrobe items and weather ratings.
- `systems/food.json` defines food, drinks, alcohol, and inebriation thresholds.
- `systems/general_items.json` defines hygiene, health, school, and ticket items.
- `systems/stores.json` defines shop hours, prices, stock, and discounts.
- `runtime/new_game_state.json` defines the complete initial runtime snapshot.
- `systems/simulation_events.json` defines all legal state-changing operations.
- `systems/save_system.json` defines slots, atomic writes, recovery, and migrations.
- `vertical_slice/manifest.json` locks the required first-playable content scope.

Global content follows the same declarative rules as character packages and cannot
contain executable code.
