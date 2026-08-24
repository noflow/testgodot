# Global content

Character-owned quests, conversations, texts, and outcomes live inside that
character's `.character` package. Content involving locations, institutions, or
unnamed service NPCs lives here.

- `opening/global_quests.json` contains the opening institutional and tutorial quests.
- `opening/global_conversations.json` contains their service conversations.
- `opening/opening_week.json` maps Tuesday through Sunday across all seven blocks.
- `world/locations.json` defines walkable locations, rooms, hours, and actions.
- `world/transportation.json` defines travel modes, routes, time, cost, and delays.
- `systems/education.json` defines Westshore programs, courses, schedules, and grading.
- `systems/employment.json` defines jobs, requirements, interviews, and promotions.
- `systems/repeatable_activities.json` defines routine actions and simulation effects.
- `systems/economy.json` defines accounts, budgets, recurring bills, debt, and income.
- `systems/inventory.json` defines containers, item rules, and starting loadouts.
- `systems/clothing.json` defines wardrobe items and weather ratings.
- `systems/food.json` defines food, drinks, alcohol, and inebriation thresholds.
- `systems/general_items.json` defines hygiene, health, school, and ticket items.
- `systems/stores.json` defines shop hours, prices, stock, and discounts.

Global content follows the same declarative rules as character packages and cannot
contain executable code.
