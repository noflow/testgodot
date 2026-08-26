# Port Alder Housing Playbook

Status: implemented foundation  
Presentation: Housing phone app plus Ren'Py-style directional location navigation

## Player loop

Housing is an open-ended sandbox system. The player may browse listings at any
time, work toward their requirements, acquire more than one residence, and decide
when to move. A lease or mortgage continues after moving elsewhere until a future
contract-ending feature is used; moving is not an automatic cancellation.

1. Open Housing on the phone.
2. Compare upfront and monthly costs.
3. Review unmet enrollment, credit, income, or cash requirements.
4. Acquire a qualified listing.
5. Move in now or keep the property for later.
6. Navigate its rooms with the same on-scene left, right, and outside arrows used throughout the city.
7. Pay monthly charges through the economy system.

## Initial market

| Listing | Tenure | Upfront | Monthly total | Main requirements |
| --- | --- | ---: | ---: | --- |
| Cypress Hall Student Room | Rental dorm | $1,450 | $950 | Enrolled, credit 550 |
| Greyport Affordable Studio | Rental studio | $2,065 | $1,490 | Credit 620, $3,375 monthly income |
| Harbor View Starter Condo | Purchase | $34,200 | $1,927 | Credit 680, $5,200 monthly income |

Rental upfront cost is first month's rent plus the deposit and application fee.
Purchase upfront cost is the down payment plus closing costs. Income is calculated
from active jobs using hourly pay and weekly hours.

## Contracts and payments

Acquisition creates a unique contract in `player.housing.contracts`. Rentals also
create a lease summary; purchases create an owned-property summary and mortgage
balance. Upfront payments draw from checking, savings, then wallet cash and are
written to the immutable economy ledger.

Active contracts are due on the first of each month. Rental charges include rent
and utilities. Condo charges include mortgage payment, condo fee, and utilities.
An on-time mortgage payment applies interest first and reduces principal with the
remainder. Each attempt is recorded once in both housing payment history and the
recurring-transaction ledger.

If available funds cannot cover a monthly charge:

- the full charge becomes outstanding housing arrears;
- the contract retains its own outstanding balance;
- the credit score falls by eight points;
- the phone's Money app offers an arrears payment action.

## Moving and households

Moving consumes one activity block. It changes:

- `household_state` and its member list;
- the active residence, tenure, and exact room;
- the world location and discovery state;
- wardrobe, bathroom, kitchen, and garage storage access;
- the durable move history.

The first move away saves the Hale household and housing agreement. Moving back
restores family members, privacy rules, chores, storage locations, and any $250
job-path family rent that was already active. Other leases and mortgages remain in
the player's portfolio.

## Content authoring

Listings live in `content/systems/housing.json` under `housing_listings`. Each
listing needs a unique ID, rental or purchase tenure, a registered location,
residence and arrival rooms, requirements, costs, and a storage-access mapping.
Locations and every navigable room live in `content/world/all_locations.json`.
Routes to viewing locations live in `content/world/transportation.json`.

Adding another property does not require changing the Housing phone interface.
Once its data validates, it appears automatically with a live qualification report.

## Current boundary

This milestone establishes searching, qualification, acquisition, moving,
recurring payments, arrears, mortgage amortization, VN room access, saves, and
autosaves. Future housing work can add roommates and partners, lease termination,
selling and refinancing, furnishing, property condition, larger homes, and family
capacity without replacing the contract model.
