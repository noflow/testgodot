# Port Alder Life Sim — Game Design Playbook

Status: pre-production working specification  
Engine: Godot 4 with GDScript  
Presentation: 2D top-down exploration with VN-style dialogue scenes

## High concept

The player controls an 18-year-old man beginning adult life in Port Alder, a fictional Pacific Northwest-inspired coastal city. He starts in his parents' home shortly before the autumn college semester. From the opening conversation onward, the game becomes a sandbox: attend college, work, combine both, build relationships, move homes, develop a career, marry, have children, and age through an entire life.

The tone is dramatic and mature. Intimate adult scenes are suggestive and non-graphic.

## Design pillars

- Personal freedom without one correct life path
- NPCs with schedules, homes, memories, relationships, and independent lives
- Meaningful time and opportunity costs
- Authored VN-quality emotional scenes
- Emergent consequences between simulation systems
- A life summary rather than a traditional victory condition

## Protagonist creation

The protagonist is always male and begins at age 18. The player selects:

- First and last name
- Birthday
- Face
- Eye color
- Skin tone
- Hairstyle
- Height
- Body type
- Three positive traits receiving an initial increase
- Three challenging traits receiving an initial increase
- Three core values
- Starting archetype
- Two hobbies
- Financial background
- Family structure and siblings

Romantic interest develops organically through player choices. No orientation label is selected at creation.

Health, immunity, fertility, alcohol tolerance, and reproductive information develop or are discovered organically during play.

## Daily time

Each day contains seven activity blocks:

1. Early Morning
2. Morning
3. Lunch
4. Afternoon
5. Evening
6. Late Evening
7. Night

Short actions such as showering, changing clothes, eating a snack, checking the phone, or sending messages use only part of a block. Work, school, movies, parties, and long dates may occupy multiple blocks.

## Calendar and aging

- Real-style twelve-month calendar
- Four seasons
- Character birthdays and annual anniversaries
- All persistent characters age
- Opening date is a Tuesday in August, several weeks before Westshore's fall semester
- First year target: approximately 12–15 hours of authored and sandbox content
- Later routine years can be accelerated
- Spotlight play returns automatically for major events
- Pregnancy loss is excluded; established pregnancies result in one child or twins

## Port Alder

Port Alder is a coastal city of approximately 350,000 people. Initial districts:

- Alder Heights — starting family neighborhood
- Westshore College District
- Harbor Centre — downtown
- Lantern District — entertainment and nightlife
- Greyport — affordable and industrial
- Cedar Vale — suburban family district
- Alder Bay Park and waterfront
- Mariner Row — shopping
- St. Maren Medical District
- Crown Point — luxury housing and services

Major institutions include Westshore College, St. Maren Medical Center, Forge Fitness, Harborlight Cinema, Port Alder Credit Union, and Harbor Employment Centre.

## Transportation

Supported transportation:

- Walking
- Bus
- Taxi
- Family or personal car

Travel consumes time and can cause weather exposure. Bikes, trains, subways, and rideshare services are excluded.

## Weather and clothing

The wardrobe supports:

- Underwear
- Shirt
- Pants
- Socks
- Shoes
- Hat
- Jacket or coat
- Gloves
- Scarf
- Bras and panties for applicable characters and custom content

Clothing has warmth, rain protection, wind protection, cleanliness, comfort, condition, formality, and style. Wearing summer clothing in winter or unsuitable clothing in heavy rain increases Energy loss, discomfort, Wetness, and illness risk. Hot-weather overdressing accelerates Hydration and Hygiene loss.

## Protagonist statistics

Daily needs use a 0–100 scale:

- Energy
- Fatigue
- Hunger
- Hydration
- Hygiene
- Mood
- Stress
- Loneliness
- Inebriation

Long-term attributes include:

- Health
- Strength
- Stamina
- Fitness
- Flexibility
- Coordination
- Immunity
- Recovery
- Confidence
- Self-esteem
- Focus
- Motivation
- Discipline
- Creativity
- Intelligence
- Emotional Intelligence
- Life Satisfaction
- Charisma
- Empathy
- Humor
- Manners
- Assertiveness
- Responsibility
- Reliability
- Inhibition

Reputation is tracked separately across academic, professional, social, family, romantic, and community contexts.

## Skills

Trainable skills range from Level 0 to Level 250.

- 0: Untrained
- 1–24: Beginner
- 25–49: Novice
- 50–84: Competent
- 85–119: Professional
- 120–159: Advanced
- 160–199: Expert
- 200–229: Elite
- 230–249: World-class
- 250: Master

Breakthrough challenges occur at important thresholds. Level 250 requires a unique mastery challenge. Repeating trivial activities eventually stops providing useful experience.

## Phone

The smartphone is the central life-management interface:

- Contacts
- Messages
- Calendar
- Quests
- Character Profile
- Relationships
- Jobs
- Banking
- Housing
- City Map
- Transportation
- Shopping
- Education
- Social Media
- Health records
- Household
- Settings

Dates and appointments automatically enter the calendar. Double-booking remains possible and creates believable consequences.

## Quest tracker

Quest categories:

- Main Life Goals
- Character Stories
- Opportunities
- Personal Goals
- Routine Activities

Quests can have dates, block availability, locations, travel estimates, prerequisites, expenses, and expiration rules. Failure normally changes the story rather than ending the game.

## Education

Westshore College operates during Morning, Lunch, and Afternoon and closes afterward.

Programs include:

- Arts and Humanities
- Business
- Computer Systems
- Education
- Health Sciences
- Social Sciences
- Undeclared Studies

Credentials include certificates, diplomas, and degrees. Students may attend part-time or full-time. The system tracks tuition, schedules, attendance, assignments, projects, examinations, grades, scholarships, loans, internships, changing programs, withdrawal, and return.

While actively enrolled, the protagonist lives with his parents rent-free and receives a weekly allowance based on family background. Part-time work remains available.

## Employment

Jobs are obtained through applications, networking, NPC recommendations, campus listings, and hidden opportunities. Positions may require:

- Skills
- Personality traits
- Education
- Certifications
- Experience
- Reputation
- Physical attributes
- Availability
- Interview performance

Work supports fixed and variable schedules, probation, performance, raises, promotions, benefits, shift trades, resignation, layoffs, and termination.

Adult sex work is legal and regulated in Port Alder for consenting adults aged 18 or older. It remains mature but non-graphic, voluntary, and governed by health, safety, consent, privacy, and relationship systems.

## Economy

Port Alder uses fictional dollars. Provisional balance anchors:

- Minimum wage: $18/hour
- Household rent when not enrolled: $250/month beginning September 1
- Part-time student work: approximately $500–$1,900 monthly depending on hours
- Room in shared housing: approximately $700–$1,100 monthly
- Studio: approximately $1,200–$2,100 monthly
- Detached house rent: approximately $3,000–$5,500 monthly
- Full-time college tuition: approximately $4,000 per semester
- Monthly groceries for one adult: approximately $280–$500

The economy includes wages, taxes, rent, mortgages, utilities, tuition, debt, credit, clothing, food, transportation, healthcare, childcare, child support, property ownership, savings, and simple investments.

Unmarried parents living separately may owe or receive child support based on income, custody, number of children, childcare, and medical costs.

## Housing

Rentable and purchasable housing includes:

- Parents' home
- Dorms
- Rented rooms
- Studios and apartments
- Condos
- Townhouses
- Detached houses
- Luxury homes
- Penthouses

Homes are walkable and contain functional rooms. Household members follow schedules and negotiate bills, chores, guests, privacy, children, and shared finances.

## Food and cooking

Food remains intentionally simple:

- Snacks
- Junk food
- Basic meals
- Healthy meals
- Water
- Juice
- Beer
- Wine
- Spirits

Cooking supports snacks, packed lunches, household meals, healthy meals, and cooking for dates. Food quality affects Hunger, Health, Energy, Mood, and Fitness recovery.

## Alcohol

Inebriation ranges from sober through severely intoxicated. It affects Focus, Coordination, judgment, effective Inhibition, dialogue, driving, and next-day condition. NPC reactions vary by personality.

Severely intoxicated characters cannot consent to an intimate encounter. Alcohol never overrides boundaries.

## Health

Port Alder contains:

- St. Maren Medical Center
- Family doctors
- Therapists
- Relationship counseling
- Sexual-health services
- Pharmacies

Health systems cover illness, injuries, appointments, therapy, medication, fertility, pregnancy care, STI testing and treatment, medical bills, and insurance.

## Fertility and children

Adult fertility tiers range from infertile through exceptionally fertile. Exact values are normally hidden until tested. Reproductive capability is stored separately from gender identity.

Pregnancy calculations consider both adults' reproductive profiles, fertility, contraception, health, age, and sandbox settings. Established pregnancies always lead to one child or twins.

Children progress through infant, toddler, young-child, preteen, teenager, and young-adult stages. Adult relationship systems never apply before age 18.

## Relationships

Visible meters for eligible adult NPC relationships:

- Friendship
- Love
- Attraction
- Lust

Supporting variables:

- Trust
- Respect
- Resentment
- Jealousy
- Comfort
- Commitment
- Compatibility
- Relationship Satisfaction

Each primary relationship meter has five levels. Advancing a level requires points and relationship-specific due diligence. Major NPCs receive five authored relationship chapters with friendship, romance, conflict, and long-term branches.

Relationship agreements include casual dating, undefined dating, exclusivity, open relationships, serious partnership, engagement, marriage, separation, and former partners. NPC reactions to dating other people depend on agreements, honesty, jealousy, Trust, and personality.

## Adult preferences

Eligible adult characters can have interests, curiosities, dislikes, hard limits, and fetishes. Some begin established; others may develop consensually during relationships. Charm may improve respectful communication with an undecided or flexible NPC but never overrides refusal or a hard boundary.

Adult scenes remain non-graphic. Family members, minors, animals, nonconsensual activity, and uninvolved public participants are excluded.

## STI system

STI risk depends on exposure, protection, preventive care, and treatment—not simply number of partners. Testing, disclosure, treatment, and partner notification connect to healthcare and relationships.

Transmitting an STI may cause Love and Trust loss, Resentment, breakup, blocking, temporary no contact, or permanent estrangement. Consequences depend strongly on prior knowledge, disclosure, honesty, and broken agreements.

## NPC simulation

Major NPCs have:

- Age and birthday
- Home and household
- Work or school schedule
- Days off
- Personality and values
- Skills and goals
- Orientation and relationship eligibility
- Private reproductive and adult-preference profiles
- Social connections
- Memories
- Independent life decisions
- Five relationship chapters

NPCs may work weekdays, weekends, nights, rotating shifts, or flexible schedules. A free calendar block does not guarantee willingness to meet.

## Opening cast

Initial major characters:

- Elena Reyes-Hale, 45 — mother and clinic administrator
- Daniel Hale, 47 — father and transit mechanic
- Lily Hale, 19 — older sister and Westshore student
- Emma Rowan, 18 — childhood friend and Literature student
- Marcus Lee, 19 — childhood friend, Film student, and cinema employee
- Maya Chen, 18 — Pre-Medical student
- Chloe Bennett, 19 — trans woman, Visual Arts student
- Nadia Flores, 20 — Nursing student
- Theo Grant, 20 — trans man and Computer Systems student
- Sofia Alvarez, 23 — restaurant supervisor
- Claire Donovan, 21 — retail worker
- Jade Mercer, 25 — licensed professional companion
- Hannah Brooks, 27 — nurse
- Rachel Morgan, 24 — personal trainer
- Olivia Price, 32 — senior corporate attorney

All opening major characters are at least 18. Younger characters appear only as dependent children within family systems.

## Character packages and mods

Every major character is stored in exactly one file named after them:

```text
chloe_bennett.character
```

The compressed character container holds the character profile, schedules, quests, conversations, texts, relationship chapters, outcomes, portraits, and other character-specific assets. Save files store changing runtime state separately.

New `.character` files can be imported through the Content and Mods interface and introduced to existing saves through a configured entry event.

The mod system is also planned to support traits, adult preferences, jobs, clothing, food, dialogue, events, NPCs, and locations. Standard content packages contain data and assets but no executable code.

## Conversation design

Major scenes are fully prewritten. Routine dialogue uses modular prewritten lines selected from simulation context. The game does not require an LLM.

Conversation types:

- Major VN scenes
- Standard topic conversations
- Contextual dialogue
- Ambient dialogue
- Text messages and phone calls
- Multi-character scenes

Choices carry tone tags such as Honest, Supportive, Playful, Flirty, Romantic, Confident, Blunt, Defensive, Deceptive, Angry, and Avoidant. Conversations can create memories and affect relationship variables.

Repetition controls include once-only flags, cooldowns, relationship-level restrictions, alternate wording, and later-life replacements.

An optional local-LLM provider is parked in the post-launch research backlog and is not part of the baseline design.

## Opening sequence

The game opens on a Tuesday morning in August. Elena enters the protagonist's room and tells him to choose a direction:

1. Attend Westshore College
2. Find employment
3. Attend college and work

College enrollment waives household rent and activates the weekly allowance. Choosing work without enrollment creates a recurring $250 rent obligation beginning September 1.

After Elena leaves, the sandbox begins immediately. Initial optional content includes:

- Under This Roof — family rules and chores
- One Year Ahead — Lily's program-change storyline
- Before Everything Changes — Emma's Alder Bay walk
- One Last Summer Movie — Marcus at Harborlight Cinema
- Enroll at Westshore
- Find Employment
- First Rep — Forge Fitness and Rachel
- Ready for Port Alder — weather and wardrobe
- Getting Around Port Alder — transportation

The opening conversation, its three life-path branches, the first household quest,
and Elena's first follow-up text are authored in `elena_reyes_hale.character`.

The first content milestone also includes complete opening quests and conversations
for Lily, Emma, Marcus, and Rachel. Global packages define Westshore enrollment,
full-time and part-time job searches, weather-aware wardrobe onboarding, city
transportation onboarding, the Westshore enrollment advisor, and the Harbor
Employment Centre orientation.

The opening Tuesday-through-Sunday calendar is now mapped across all seven daily
blocks. The canonical city registry defines ten Port Alder districts, sixty-one
destinations, and more than three hundred rooms, including every opening NPC home,
rentable and purchasable housing, education, work, shopping, entertainment, health,
family, and outdoor spaces. Transportation data supplies walking, bus, taxi, and car
time and cost.

The initial playable systems catalog defines seven Westshore programs, fifteen
first-semester courses, thirteen jobs with requirements and promotions, a scored
interview model, and twenty-seven repeatable life activities.

The economy and ownership milestone defines three starting financial backgrounds,
four account types, recurring bills and income, inventory containers, starting
loadouts, thirty clothing items, food and alcohol, general supplies, and seven
initial stores. All prices remain provisional until simulation balancing.

The technical architecture milestone defines the complete new-game runtime state,
declarative simulation operations, snapshot-plus-event-log saves, atomic writes,
recovery backups, content manifests, and forward-only version migration.

The First Week Foundations vertical slice is fully specified with its playable
scope, controls, accessibility baseline, Godot architecture, implementation phases,
explicit exclusions, completion gate, and machine-readable acceptance tests.

Godot 4.7.2 Phase 0 is implemented with the project configuration, boot validation,
main menu, input map, audio buses, macOS export preset, coding conventions, and a
headless foundation test runner.

Phase 1 now includes recursive content loading and typed indexes, complete new-game
state resolution, distributed starting inventory, the seven-block calendar clock,
and an atomic event processor for the first playable state changes.

## Next milestones

1. Expand event handlers as their gameplay systems come online
2. Implement the VN dialogue and quest systems with Elena's opening scene
3. Implement Hale home exploration, needs, wardrobe, food, and hygiene
4. Implement the phone, calendar, messages, relationships, map, and weather
5. Implement city travel and the required institutional and NPC activities
6. Implement saves, recovery, Sunday review, settings, and accessibility
7. Stabilize the vertical slice against all acceptance tests
8. Resume broader content expansion, alternative households, and the September calendar
