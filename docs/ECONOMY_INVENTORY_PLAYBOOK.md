# Economy, Inventory, and Shopping Playbook

## Starting finances

The selected family financial background changes starting cash, checking, savings,
weekly school allowance, shared-car access, and the quality of the initial wardrobe.

| Background | Cash | Checking | Savings | Weekly school allowance |
| --- | ---: | ---: | ---: | ---: |
| Limited | $40 | $260 | $200 | $60 |
| Standard | $75 | $625 | $800 | $100 |
| Comfortable | $120 | $1,380 | $3,000 | $150 |

Players who are not enrolled owe $250 rent beginning September 1. Enrolled players
receive the appropriate allowance each Monday. The phone ledger records purchases,
income, tax, tuition, rent, healthcare, transportation, debt, and transfers.

The Money app performs catch-up processing without duplicating a due transaction.
Allowances retain their Monday ledger date even when the app is opened later. Rent
uses Cash and Checking automatically; an unaffordable payment becomes arrears and
applies Elena's authored Resentment and Trust effects. Arrears may later be paid
through the normal payment priority, including available credit. Credit-card
minimums run on the fifteenth, with on-time and missed results changing Credit Score.
Student-loan interest capitalizes monthly at the authored 4.5 percent annual rate.

Tuition is $4,000 full-time or $2,200 part-time. Paying during enrollment now uses
the Tuition ledger category. Aid-pending plans retain an explicit balance; resolving
the financial-aid quest applies the background-specific award, and the Money app can
make partial or full payments against the remainder.

Every Monday closes the prior week's immutable budget summary. It reports starting
and ending net account balance, gross and net employment income, allowance,
purchases, transportation, healthcare, tuition, rent, and debt payments.

The system includes checking, savings, cash, a starter credit card, student loans,
weekly payroll, provisional tax withholding, credit history, and child support.
Child support applies to unmarried parents living separately and considers both
incomes, custody, children, childcare, and medical costs.

## Inventory

Items may be carried or stored in the bedroom wardrobe, bathroom, kitchen, or
garage. Containers limit both weight and slots. Clothing tracks condition and
cleanliness; food tracks freshness; medicine can track expiration; hygiene items
track remaining uses.

Discarding an item requires confirmation. Items can also be stored, given, sold,
returned, or moved into the carried inventory where appropriate.

## Clothing and weather

The initial catalog contains thirty clothing items across underwear, bras, shirts,
pants, socks, shoes, hats, jackets, gloves, and scarves. Clothing records Warmth,
Rain Protection, Wind Protection, Comfort, Formality, and Style.

The three starting wardrobes always include the essentials. Standard and
comfortable backgrounds also begin with winter clothing, while the limited
background must budget for cold weather before winter arrives.

## Food and alcohol

The food catalog includes snacks, junk food, basic meals, healthy meals, water,
juice, soda, beer, wine, and spirits. Food affects Hunger, Energy, Hydration, Mood,
and long-term health pressure without becoming a detailed cooking simulator.

Alcohol is restricted to adults aged 18 or older. Inebriation uses six levels from
Sober through Severely Intoxicated. It affects Hydration and Inhibition, blocks
driving at the configured threshold, and blocks intimate consent at severe
intoxication. Food and water ease symptoms but do not instantly remove alcohol.

## Stores

Twelve initial shops cover groceries, everyday clothing, formalwear, pharmacy
items, school supplies, gym goods, cinema concessions, department-store goods,
athletic wear, personal essentials, and food-hall meals. Seven city shops are joined
by five occupied storefronts in Port Alder Galleria. Stores have opening hours,
price multipliers, seasonal stock, discounts, and sold-out states.

The Shopping app now browses all twelve catalogs and delivers successful purchases
to Wardrobe, Kitchen, Bathroom, Garage, or Carried storage according to item type.
Quotes apply store multipliers, combined eligible student/employee discounts, and
the authored seven-percent sales tax with grocery exemptions. Payment splits across
Cash, Checking, and the starter credit card in authored priority order. Inventory
capacity and total purchasing power are validated before the transaction commits;
declines leave both money and inventory unchanged. Each completed purchase saves an
itemized receipt with subtotal, discount, tax, total, payment split, and return flag.
Selecting an occupied storefront while physically inside the mall opens that one
catalog even before remote Shopping access is unlocked. The mall directory itself
contains sixteen stable unit IDs: five occupied, two coming soon, one rotating
pop-up, and eight vacant expansion units.

## Source data

- `content/systems/economy.json`
- `content/systems/inventory.json`
- `content/systems/clothing.json`
- `content/systems/food.json`
- `content/systems/general_items.json`
- `content/systems/stores.json`
