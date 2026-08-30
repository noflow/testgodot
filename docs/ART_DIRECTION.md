# Port Alder Art Direction

Status: production baseline  
Presentation: grounded, static visual-novel backgrounds and transparent character portraits

## Core look

Port Alder uses polished semi-realistic digital illustration for a dramatic, mature
contemporary story. Environments should feel lived in and specific without becoming
photographic or visually noisy. Character anatomy, age, clothing, and expressions
remain believable. Avoid exaggerated anime proportions, glamour posing, childish
styling, and neon or fantasy palettes unless a specific story location calls for it.

The opening palette combines slate blue, muted teal, warm cedar, cream, charcoal,
and restrained rust accents. Coastal daylight is cool and soft; interior practical
light and natural wood provide warmth.

## Background staging

- Compose backgrounds at 16:9; 1920×1080 is the preferred final size.
- Keep the bottom 35 percent relatively calm and darker for the dialogue interface.
- Preserve open center or side staging space for one or more character portraits.
- Show believable entrances and exits that support the authored navigation graph.
- Do not paint navigation arrows, interface elements, people, text, or logos into a background.
- Time, weather, and season variants must preserve the base room geometry and camera.

## Character staging

- Use a tall transparent canvas; 900×1600 or a similar ratio is preferred.
- Keep the full head, shoulders, hands, and silhouette safely inside the canvas.
- Age characters accurately and use practical, character-specific contemporary clothing.
- Expression variants preserve identity, outfit, proportions, camera, and lighting.
- Portraits must have genuine alpha transparency and no painted backdrop or floor.
- Sexualized presentation is reserved for explicitly authored adult scenes; everyday portraits remain grounded and non-graphic.

## Room-first production policy

Room art is the active production priority. Every mapped room will receive a unique
base daytime background before time, weather, or season variants are produced.
Locations are completed one at a time so connected rooms share believable
architecture, materials, sightlines, and exterior continuity. Character portrait
work is deferred; existing portrait data and completed assets remain intact.

The fifty-seven completed base-art locations are the Hale Home, Alder Heights Residential
Street, Alder Heights Bus Stop, Westshore Administration Office, Harbor Employment
Centre, Alder Bay Park, Harborlight Cinema, Forge Fitness, Westshore Campus, and
Bayview Café, plus Port Alder Marina, Alder Bay Beach, Port Alder Galleria, Harbor Centre
Downtown, Harbor Centre Apartments, Harbor View Condominiums, Port Alder Credit
Union, Port Alder City Hall, Port Alder Realty, Harbor Centre Business Services,
Cypress Hall Dorm, Maple Hall Dorm, the Westshore Shared Student Apartment, and the
Westshore Bookshop, Lantern Gallery, Lantern District Street, La Brisa Kitchen,
Tideglass Club, Harbor Companion Cooperative, the Rowan Family Home, Jade's Downtown
Condo, Greyport Main Street, the Lee Family Apartment, the Flores Family Townhouse, and the
Greyport Shared Apartment, the Donovan Family Apartment, Greyport Distribution, and the
Port Alder Transit Depot, Greyport Studios, Undertow Nightclub, Cedar Vale Residential
Street, Rachel's Townhouse, Cedar Vale Townhouses, Cedar Vale Detached Homes, Cedar Vale Care Home, Cedar Vale Family Centre, Mariner Row Shopping Street, Mariner Market, Northline Outfitters, Harbor Formalwear, Mariner Home Goods, Port Alder Auto, St. Maren Medical Center, St. Maren Community Clinic, St. Maren Family Doctors, Harbor Wellness Therapy, and St. Maren Sexual Health Centre. Together they provide 321 unique base-day PNG
backgrounds. Each base image is marked ready in the
art registry, while backlog tasks with additional time, weather, or season
requirements remain in progress until those variants are finished.

### Hale Home batch prompt set

The player-bedroom image was the primary visual reference. The entryway and living
room generations were also used as continuity references for connected ground-floor
rooms and the property exterior.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production visual-novel background for a Godot game. Create the named room in the established Hale family home in the fictional coastal city of Port Alder. Grounded semi-realistic contemporary-drama illustration with painterly materials and restrained clean linework. Eye-level 16:9 composition, believable middle-class architecture, open character staging space, and a calm darker lower region for dialogue. Soft late-August daytime coastal light; slate blue, muted teal, warm cedar, cream, charcoal, and restrained rust accents. Preserve clear believable entrances and exits for room-to-room navigation. No people, character sprites, navigation arrows, interface, text, logos, watermark, or fisheye distortion.

Room-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Upstairs landing | `upstairs_landing.png` | Compact stair landing connecting the second floor to the entryway below. |
| Upstairs hall | `upstairs_hall.png` | Family bedroom corridor with distinct doors and coherent upstairs geometry. |
| Entryway | `entryway.png` | Main front-door foyer, stairs, coat storage, and access toward the living spaces. |
| Family bathroom | `family_bathroom.png` | Shared practical bathroom with tub-shower, vanity, toilet, and lockable hall door. |
| Lily's bedroom | `lily_bedroom.png` | Older sister's mature, personalized bedroom with bed, desk, storage, and hall door. |
| Parents' bedroom | `parents_bedroom.png` | Calm adult primary bedroom with restrained decor, storage, and hall access. |
| Living room | `living_room.png` | Warm family gathering room connected naturally to the foyer and dining area. |
| Kitchen | `kitchen.png` | Lived-in family kitchen with work surfaces, appliances, and clear adjacent-room exits. |
| Dining room | `dining_room.png` | Six-place family dining space bridging the kitchen and living room. |
| Laundry room | `laundry_room.png` | Practical utility room linking the kitchen side of the house to the garage. |
| Garage | `garage.png` | Single-family attached garage with shared car, storage, workbench, and interior door. |
| Front yard | `front_yard.png` | Blue-gray two-story coastal Craftsman exterior, driveway, porch, and neighborhood path. |
| Backyard | `backyard.png` | Private fenced garden, patio, lawn, and rear view of the same home. |

All files are saved under
`res://assets/art/backgrounds/hale_home/`. The existing player bedroom completes
the 14-destination set.

### Opening routes batch prompt set

This batch completes the walk from the Hale property to the bus and every room at
the player's first college and employment destinations. The Hale front yard was
used as the neighborhood continuity reference. Each building's reception or main
floor was generated first and then used as the architectural reference for its
connected rooms.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination with grounded semi-realistic contemporary-drama digital illustration, painterly materials, and restrained clean detail. Use believable navigable geometry, clear connected entrances and exits, open character staging space, and a calm darker lower region for dialogue UI. Soft late-August weekday coastal light with slate blue, muted teal, warm cedar, cream, charcoal, and restrained rust. Preserve the architecture, palette, weather, and rendering style of the supplied location reference. No people, character sprites, navigation arrows, interface, readable notices or screens, text, logos, trademarks, or watermark.

Destination-specific briefs:

| Location | Destination | Production file | Brief |
| --- | --- | --- | --- |
| Alder Heights Residential Street | Hale Block | `alder_heights_residential_street/hale_block.png` | Same Hale house seen from across the wet residential street, with routes continuing both ways and back to the property. |
| Alder Heights Residential Street | Neighborhood Corner | `alder_heights_residential_street/neighborhood_corner.png` | Four-way neighborhood junction toward Hale Block, the bus shelter, Alder Bay Park, and Forge Fitness. |
| Alder Heights Bus Stop | Bus Shelter | `alder_heights_bus_stop/shelter.png` | Cedar-and-glass shelter, bench, abstract route panels, bay view, and pedestrian return path. |
| Westshore Administration | Reception | `westshore_administration_office/reception.png` | College service lobby with reception counter, courtyard exit, and advisor-office continuation. |
| Westshore Administration | Enrollment Advisor Office | `westshore_administration_office/advisor_office.png` | Private enrollment consultation room connected between Reception and Financial Aid. |
| Westshore Administration | Financial Aid Office | `westshore_administration_office/financial_aid.png` | Consultation counter and semi-private desks connecting the advisor and Records rooms. |
| Westshore Administration | Student Records | `westshore_administration_office/records.png` | Secure service counter, closed files, archive storage, and one return doorway. |
| Harbor Employment Centre | Job Search Floor | `harbor_employment_centre/job_floor.png` | Open public-service floor with blank job boards, work tables, harbor windows, counseling route, and downtown exit. |
| Harbor Employment Centre | Career Counselor Desk | `harbor_employment_centre/counselor_desk.png` | Semi-private two-chair counseling office between the Job Search Floor and computers. |
| Harbor Employment Centre | Application Computers | `harbor_employment_centre/computer_area.png` | Two rows of blank workstations, printer station, and connections to counseling and interview practice. |
| Harbor Employment Centre | Practice Interview Room | `harbor_employment_centre/interview_room.png` | Small two-seat mock-interview room with an observation window and one return doorway. |

### Activity circuit batch prompt set

This batch completes the park, cinema, and gym as three fully navigable locations.
The Waterfront Path, Cinema Lobby, and Fitness Front Desk were generated as anchor
images; every connected room used its location anchor as the architecture, palette,
lighting, material, and rendering-style reference.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel background for the Godot game Port Alder. Create the named mapped destination as a grounded semi-realistic contemporary-drama digital illustration that matches the supplied location anchor. Preserve connected architecture, clear entrances and exits, open character staging, and a calm darker lower region for dialogue UI. Use believable practical materials and soft late-August coastal light. No people or reflections of people, character sprites, navigation arrows, interface, readable notices or screens, text, logos, trademarks, or watermark.

Destination-specific briefs:

| Location | Destination | Production file | Brief |
| --- | --- | --- | --- |
| Alder Bay Park | Waterfront Path | `alder_bay_park/waterfront_path.png` | Wet landscaped bay path branching toward Alder Heights, the beach, picnic lawn, and restroom pavilion. |
| Alder Bay Park | Picnic Lawn | `alder_bay_park/picnic_lawn.png` | Open sloped lawn with cedar tables and paths to the waterfront, lookout, and playground. |
| Alder Bay Park | Bay Lookout | `alder_bay_park/lookout.png` | Sheltered cedar-and-stone overlook with a broad bay view and path toward Bayview Cafe. |
| Alder Bay Park | Playground | `alder_bay_park/playground.png` | Empty cedar-and-teal play area with routes toward the picnic lawn and restrooms. |
| Alder Bay Park | Public Restrooms | `alder_bay_park/public_restrooms.png` | Clean slate-and-cedar facility with stalls, sinks, mirrors, and an exterior park doorway. |
| Harborlight Cinema | Lobby | `harborlight_cinema/lobby.png` | Independent-cinema ticket lobby with abstract posters and routes to the street, concessions, and auditorium. |
| Harborlight Cinema | Concessions | `harborlight_cinema/concessions.png` | Warm snack counter with blank menus and routes to the lobby, side auditorium, and staff room. |
| Harborlight Cinema | Auditorium | `harborlight_cinema/auditorium.png` | Medium tiered theater with charcoal-rust seats, aisle lights, and a blank screen. |
| Harborlight Cinema | Side Auditorium | `harborlight_cinema/side_auditorium.png` | Smaller intimate screening room connected to concessions and the main auditorium. |
| Harborlight Cinema | Staff Room | `harborlight_cinema/staff_room.png` | Employee break room with lockers, kitchenette, blank notice board, and concessions doorway. |
| Forge Fitness | Front Desk | `forge_fitness/front_desk.png` | Cedar-and-charcoal reception area opening to the residential street and strength floor. |
| Forge Fitness | Strength Floor | `forge_fitness/strength_floor.png` | Safe free-weight and resistance area with racks, benches, mirrors, and connected training rooms. |
| Forge Fitness | Cardio Floor | `forge_fitness/cardio_floor.png` | Windowed treadmill, elliptical, rowing, and cycling area with inactive screens. |
| Forge Fitness | Group Studio | `forge_fitness/studio.png` | Open mirrored wood-floor studio with neatly stored class equipment. |
| Forge Fitness | Locker Room | `forge_fitness/locker_room.png` | Inclusive privacy-conscious changing room with lockers, cubicles, sinks, and private showers. |
| Forge Fitness | Trainer Office | `forge_fitness/trainer_office.png` | Compact two-chair coaching office overlooking the strength floor. |

### Westshore Campus batch prompt set

This batch completes all ten mapped rooms in the main college location. The
Courtyard, Library, and Cafeteria were generated as anchor images. Every connected
room then used one of those anchors to preserve the campus's cedar, charcoal slate,
coastal landscaping, lighting, and navigable architecture.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Westshore Campus destination in grounded cinematic contemporary-drama realism. Match the supplied campus anchor's Pacific Northwest coastal atmosphere, cedar wood, charcoal slate, warm practical lighting, and restrained color palette. Preserve clear believable routes to the connected rooms, open character staging space, and an uncluttered lower region for dialogue UI. No people or reflections of people, character sprites, navigation arrows, interface, readable signs or screens, letters, numbers, logos, trademarks, or watermark.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Courtyard | `westshore_campus/courtyard.png` | Wet central pedestrian hub with landscaped paths toward Administration, Library, Cafeteria, and the Transit Loop. |
| Transit Loop | `westshore_campus/transit_loop.png` | Curved campus bus loop with cedar canopy, benches, bicycle racks, and routes to both student residences and the Courtyard. |
| Library | `westshore_campus/library.png` | Two-level study library with stacks, reading areas, courtyard access, and routes toward classrooms, career resources, and the cafeteria wing. |
| Cafeteria | `westshore_campus/cafeteria.png` | Bright dining hall with a warm service counter, varied seating, courtyard windows, and routes to the Bookshop, Career Board, and Student Lounge. |
| Classrooms | `westshore_campus/classrooms.png` | Quiet teaching corridor with a visible general classroom, seating alcove, Library route, and stair toward the Science Labs. |
| Science Labs | `westshore_campus/science_labs.png` | Modern teaching laboratory with safe benches, sinks, microscopes, and routes to the classroom and computer wings. |
| Computer Labs | `westshore_campus/computer_labs.png` | Two-row workstation lab with blank screens, instructor station, and connections to the Science Labs and Art Studios. |
| Art Studios | `westshore_campus/art_studios.png` | North-lit visual-arts studio with work tables, easels, sinks, storage, and routes to the Computer Labs and Student Lounge. |
| Career Board | `westshore_campus/career_board.png` | Career-resources alcove with abstract posting board, blank kiosk, consultation table, and routes to the Library and Cafeteria. |
| Student Lounge | `westshore_campus/student_lounge.png` | Flexible social room with sofas, study tables, kitchenette, unbranded vending, and routes to the Cafeteria and Art Studios. |

### Bayview Café batch prompt set

This batch completes the three mapped café destinations. The Alder Bay Park
Lookout established the waterfront, weather, landscaping, and approach path for
the Patio. The Patio then anchored the Dining Room, and the Dining Room anchored
the Counter so the building reads as one continuous interior and exterior space.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Bayview Café destination in grounded cinematic contemporary-drama realism. Match the supplied reference's late-August Pacific Northwest waterfront, cedar architecture, charcoal slate, warm practical light, and wet coastal atmosphere. Preserve clear believable routes to connected rooms, open character staging, and an uncluttered lower region for dialogue UI. No people or reflections of people, character sprites, navigation arrows, interface, readable menus or screens, letters, numbers, prices, logos, trademarks, captions, or watermark.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Counter | `bayview_cafe/counter.png` | Cedar service counter with espresso equipment, blank register and menu boards, pastry case, workplace staging, and an open route to the Dining Room. |
| Dining Room | `bayview_cafe/dining_room.png` | Warm bay-facing tables and booths with the Counter on the left and glass doors opening to the Waterfront Patio. |
| Waterfront Patio | `bayview_cafe/patio.png` | Wet cedar-and-slate terrace overlooking the bay with routes back to the park, onward to the marina, and inside to the Dining Room. |

### Port Alder Marina batch prompt set

This batch completes the three mapped marina destinations. The Bayview Café Patio
anchored the shoreline, weather, and public approach for the Promenade. The
Promenade then established the basin and boats for the Dock Gate, and the Dock
Gate established the exterior view from the Marina Office.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Port Alder Marina destination in grounded cinematic contemporary-drama realism. Match the supplied reference's late-August Pacific Northwest bay, tied unbranded boats, cedar-and-slate architecture, dark metal safety fixtures, warm practical light, and wet coastal atmosphere. Preserve clear believable routes to connected rooms, open character staging, an uncluttered lower region for dialogue UI, accessibility, and safe dock geometry. No people or reflections of people, character sprites, navigation arrows, interface, readable signs, boat names, registration numbers, screens, letters, numbers, logos, trademarks, captions, or watermark.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Marina Promenade | `port_alder_marina/promenade.png` | Broad wet waterfront walk with café and beach continuations, landscaped seating, marina basin, and a clear gated route to the docks. |
| Dock Gate | `port_alder_marina/dock_gate.png` | Accessible secured transition to the floating docks with safe railings, tied boats, a promenade return, and the Marina Office on the right. |
| Marina Office | `port_alder_marina/marina_office.png` | Warm practical operations office with blank workstations, reception counter, consultation table, dock windows, and one return door. |

### Alder Bay Beach batch prompt set

This batch completes the three mapped beach destinations. The Port Alder Marina
Promenade and Alder Bay Park Waterfront Path jointly anchored the Boardwalk so its
east and west connections share one shoreline. The Boardwalk then established the
geography for the Shoreline and the architecture of the Changing Room.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Alder Bay Beach destination in grounded cinematic contemporary-drama realism. Match the supplied reference's late-August Pacific Northwest bay, cedar boardwalk, charcoal stone, dark metal fixtures, evergreen landscaping, natural sand and pebbles, calm steel-blue water, and wet overcast atmosphere. Preserve clear believable routes to connected rooms, open character staging, an uncluttered lower region for dialogue UI, accessibility, coastal safety, and full privacy inside the changing facility. No people or reflections of people, character sprites, navigation arrows, interface, readable signs, locker numbers, screens, letters, numbers, logos, trademarks, captions, or watermark.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Boardwalk | `alder_bay_beach/boardwalk.png` | Broad wet cedar junction linking the park, marina, shoreline access, and changing facility. |
| Shoreline | `alder_bay_beach/shoreline.png` | Quiet sand-and-pebble waterline with calm bay water, an accessible mat, and one clear return route to the Boardwalk. |
| Changing Room | `alder_bay_beach/changing_room.png` | Privacy-conscious all-gender facility with enclosed cubicles and rinse stalls, lockers, benches, accessible circulation, and one Boardwalk exit. |

### Port Alder Galleria batch prompt set

This batch completes all fourteen mapped Galleria destinations. The Main Atrium
established the two-level architecture and central route. Fashion Wing, Lower Court,
and Upper Atrium then anchored their connected stores, service wings, event hall, and
expansion corridors. The empty East and West Expansion storefronts deliberately remain
clean and modular so future game packages and mods can replace individual units.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Port Alder Galleria destination in grounded mature cinematic contemporary realism. Match the supplied reference's cedar, charcoal slate, muted teal, cream, warm stone, restrained rust, practical retail lighting, believable two-level mall geometry, and coastal-city atmosphere. Preserve the authored room-to-room route, open character staging, clear floating-arrow placement, and an uncluttered lower region for dialogue UI. No people, reflections of people, mannequins, dress forms, busts, statues, human silhouettes, or other human-shaped display objects. No character sprites, navigation arrows, interface, readable signs, menus, price boards, package labels, letters, numbers, logos, trademarks, captions, or watermark; signs and screens must be blank or abstract.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Street Entrance | `port_alder_galleria/street_entrance.png` | Sheltered rainy downtown entrance with the mall visible through its doors and the Harbor Centre return route. |
| Main Atrium | `port_alder_galleria/main_atrium.png` | Two-level central hub with escalators, elevator, directory kiosk, and clear routes to Fashion Wing, Lower Court, Upper Atrium, and the street. |
| Fashion Wing | `port_alder_galleria/fashion_wing.png` | Unbranded apparel corridor connecting the Main Atrium to the Department Store without mannequins or human-shaped displays. |
| Department Store | `port_alder_galleria/department_store.png` | Wardrobe-focused sales floor with clothing racks, shoes, folded basics, fitting rooms, checkout, and a left-side return. |
| Lower Court | `port_alder_galleria/lower_court.png` | Lower junction connecting the main atrium stairs, Lifestyle Wing, Services Wing, and Food Court. |
| Lifestyle Wing | `port_alder_galleria/lifestyle_wing.png` | Sporting, wellness, fitness, and outdoor-goods storefront with a clear right-side return. |
| Services Wing | `port_alder_galleria/services_wing.png` | Generic health, phone repair, personal care, parcel locker, and banking service fronts with blank displays. |
| Food Court | `port_alder_galleria/food_court.png` | Warm unbranded food hall with blank menus, varied counters, casual seating, and a centered return route. |
| Upper Atrium | `port_alder_galleria/upper_atrium.png` | Upper balcony and escalator hub connecting Tech Wing, Home Wing, Event Space, and the lower level. |
| Tech Wing | `port_alder_galleria/tech_wing.png` | Partly prepared future retail corridor with powered-off screens, unbranded display tables, and access to West Expansion. |
| Home Wing | `port_alder_galleria/home_wing.png` | Furniture, lighting, linens, cookware, and decor storefronts with access to East Expansion. |
| Event Space | `port_alder_galleria/event_space.png` | Empty flexible hall with low modular platform, blank panels, stored tables and chairs, and no audio equipment. |
| West Expansion | `port_alder_galleria/west_expansion.png` | Maintained mod-ready corridor of vacant storefront shells returning to Tech Wing. |
| East Expansion | `port_alder_galleria/east_expansion.png` | Maintained mod-ready corridor of vacant storefront shells returning to Home Wing. |

### Harbor Centre Downtown batch prompt set

This batch completes all six mapped Harbor Centre Downtown destinations. The Galleria
Street Entrance anchored the district-side Galleria Entrance, which established the
public materials and wet coastal atmosphere. The Transit Plaza then became the central
reference for the Employment Block and Civic Square, while the Financial and Residential
blocks continue the same pedestrian spine south from employment services.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Harbor Centre Downtown destination in grounded mature cinematic contemporary realism. Match the supplied reference's wet late-August Pacific Northwest atmosphere, charcoal stone paving, cedar and dark-metal details, muted teal, cream civic stone, glass towers, mature street trees, planters, warm practical lamps, rain gardens, and accessible pedestrian design. Preserve the authored room-to-room and building-entry routes, clear open character staging, floating-arrow placement, and an uncluttered lower region for dialogue UI. No people or reflections of people, vehicles blocking routes, character sprites, navigation arrows, interface, readable signs, route maps, property listings, addresses, prices, account details, letters, numbers, logos, trademarks, captions, or watermark; signs and screens must be blank or abstract.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Harbor Transit Plaza | `harbor_centre_downtown/transit_plaza.png` | Sheltered central hub with blank route kiosks, covered bus bays, taxi lay-by, accessible curbs, and routes to Employment Block, Civic Square, and the Galleria. |
| Employment Block | `harbor_centre_downtown/employment_block.png` | Office forecourt connecting Harbor Business Services, the Employment Centre, Transit Plaza, and Financial Block. |
| Financial Block | `harbor_centre_downtown/financial_block.png` | Professional banking corridor with a sheltered blank-screen credit-union ATM lobby and north/south pedestrian spine. |
| Residential Towers | `harbor_centre_downtown/residential_block.png` | End-of-route residential forecourt with distinct apartment and condominium lobby entrances and no forward public exit. |
| Civic Square | `harbor_centre_downtown/civic_square.png` | Formal public square connecting City Hall, Port Alder Realty, and Transit Plaza around a rain garden and abstract geometric artwork. |
| Galleria Entrance | `harbor_centre_downtown/galleria_entrance.png` | Broad exterior approach with the covered Galleria doors on the right and the Transit Plaza route continuing left. |

### Harbor Centre Apartments batch prompt set

This batch completes all six mapped apartment-building destinations. The downtown
Residential Towers background anchored the practical apartment entrance and Lobby.
The Lobby then established the building's modest contemporary rental materials for
three increasingly spacious furnished model units and the communal Laundry Room.
The Roof Deck combines that interior reference with the established downtown skyline.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Harbor Centre Apartments destination in grounded mature cinematic contemporary realism. Match the supplied reference's modest Pacific Northwest rental quality, rain-dimmed late-August daylight, warm cedar, muted teal, cream walls, charcoal stone or wood flooring, dark metal, practical warm lighting, ordinary furnishings, and accessible circulation. Keep the building comfortable and well maintained but clearly midmarket rather than luxurious. Preserve the authored route, open character staging, floating-arrow placement, and an uncluttered lower region for dialogue UI. No people or reflections of people, mannequins, statues, human-shaped displays, personal photographs, character sprites, navigation arrows, interface, readable directories, mail labels, unit numbers, instructions, prices, appliance labels, book titles, letters, numbers, logos, trademarks, captions, or watermark; signs and screens must be blank or abstract.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Lobby | `harbor_centre_apartments/lobby.png` | Modest lobby with exterior glass doors, mail and package wall, blank leasing counter, seating, elevator, and routes to unit viewings and Laundry. |
| Studio Unit | `harbor_centre_apartments/studio_unit.png` | Compact open-plan furnished rental with sleeping alcove, kitchenette, wardrobe, private bathroom door, and bay-facing window. |
| One-Bedroom Unit | `harbor_centre_apartments/one_bedroom_unit.png` | Mid-tier unit with separate bedroom, practical living room, compact kitchen and dining area, bathroom, storage, and rainy bay view. |
| Two-Bedroom Unit | `harbor_centre_apartments/two_bedroom_unit.png` | Roommate- or small-family-sized rental with two bedroom doors, shared living/dining space, full kitchen, bathroom, and storage. |
| Laundry Room | `harbor_centre_apartments/laundry.png` | Clean communal facility with blank-payment washers and dryers, folding counters, utility sink, benches, carts, and two building routes. |
| Roof Deck | `harbor_centre_apartments/roof_deck.png` | Wet shared terrace with safe railings, cedar pergola and benches, ordinary tables, grill counter, coastal plants, city towers, and bay views. |

### Harbor View Condominiums batch prompt set

This batch completes all nine mapped condo destinations. The downtown Residential
Towers image anchored the polished condo entrance and Lobby. The Lobby established the
shared-building materials for Secure Parking and the private Condo Entry. From that
entry, the Living Room became the central reference for the Kitchen, Bedroom, Balcony,
Bathroom, and connected In-Suite Laundry. The home is deliberately more refined than
Harbor Centre Apartments while remaining attainable rather than penthouse-level.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Harbor View Condominiums destination in grounded mature cinematic contemporary realism. Match the supplied reference's refined but attainable Pacific Northwest owner-occupied design, rain-softened late-August light, warm cedar, muted teal, cream limestone, charcoal flooring or stone, dark metal, quality ordinary furnishings, broad bay views, practical warm lighting, and accessible circulation. Preserve the authored route, open character staging, floating-arrow placement, and an uncluttered lower region for dialogue UI. Keep the property clearly more upscale than Harbor Centre Apartments but not a penthouse or luxury resort. No people or reflections of people, mannequins, statues, human-shaped displays, personal photographs, character sprites, navigation arrows, interface, readable directories, unit or parking numbers, access codes, product or appliance labels, book titles, license plates, letters, numbers, logos, trademarks, captions, or watermark; signs and screens must be blank or abstract.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Lobby | `harbor_view_condos/lobby.png` | Refined controlled-access lobby with street-facing glass doors, blank reception console, elevator, parcel lockers, seating, and routes to the private home and parking. |
| Condo Entry | `harbor_view_condos/entry.png` | Private foyer with secure entry door, coat closet, shoe storage, console, abstract art, and a right-side opening into the Living Room. |
| Living Room | `harbor_view_condos/living_room.png` | Central bay-facing social room connecting Entry, Bedroom, Kitchen, and Balcony around quality attainable furnishings. |
| Kitchen | `harbor_view_condos/kitchen.png` | Full cedar-and-stone kitchen with island, appliances, storage, dining nook, Living Room opening, and Bathroom route. |
| Bedroom | `harbor_view_condos/bedroom.png` | Private queen bedroom with wardrobe, dresser, reading chair, abstract art, bay windows, and one Living Room return. |
| Bathroom | `harbor_view_condos/bathroom.png` | Full private bathroom with tub, walk-in shower, vanity, storage, Kitchen return, and direct In-Suite Laundry doorway. |
| In-Suite Laundry | `harbor_view_condos/laundry.png` | Compact utility room with washer, dryer, folding counter, deep sink, cabinets, baskets, and one Bathroom return. |
| Balcony | `harbor_view_condos/balcony.png` | Moderate covered private terrace with safe glass railing, two-seat furniture, planters, and a rain-darkened bay panorama. |
| Secure Parking | `harbor_view_condos/parking.png` | Clean controlled garage with blank access gate, EV chargers, bicycle storage, peripheral unbranded cars, and one Lobby return. |

### Port Alder Credit Union batch prompt set

This batch completes all four mapped Credit Union destinations. The downtown
Financial Block anchored the ATM Lobby and its wet street-facing entrance. The ATM
Lobby established the branch materials for the Teller Counter, which in turn anchors
the private Financial Advisor and Loan offices. The route supports the economy system
without displaying readable account data, rates, forms, or personal information.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Port Alder Credit Union destination in grounded mature cinematic contemporary realism. Match the supplied reference's welcoming community-financial design, wet late-August Pacific Northwest atmosphere where exterior glass is visible, charcoal stone, muted teal, warm cedar, cream walls, dark metal, restrained abstract art, safe practical lighting, privacy features, secure storage, and accessible circulation. Preserve the authored route, clear character staging, floating-arrow placement, and an uncluttered lower region for dialogue UI. No people or reflections of people, character sprites, navigation arrows, interface, readable bank names, account data, interest rates, currency amounts, forms, approval text, queue numbers, ATM or appliance labels, letters, numbers, logos, trademarks, captions, or watermark; all forms, screens and signs must be blank or abstract.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| ATM Lobby | `port_alder_credit_union/atm_lobby.png` | Secure street-facing vestibule with blank-screen ATMs, privacy dividers, deposit counter, exterior return, and entry to the staffed branch. |
| Teller Counter | `port_alder_credit_union/teller_counter.png` | Accessible community branch floor with protected teller stations, queue posts, writing counter, seating, and an advisor corridor. |
| Financial Advisor Office | `port_alder_credit_union/advisor_office.png` | Confidential planning office with desk, visitor seating, round planning table, blank monitor, locked cabinets, and two branch routes. |
| Loan Office | `port_alder_credit_union/loan_office.png` | Private loan and mortgage consultation room with oval meeting desk, three visitor chairs, blank documents, locked storage, and one return. |

### Port Alder City Hall batch prompt set

This batch completes all four mapped City Hall destinations. Civic Square anchored
the public entrance and rainy downtown geography. The Public Lobby established the
municipal building's civic-stone, cedar, charcoal, and muted-teal interior for the
Licensing Office, Family Services area, and appointment-only Hearing Room. The route
supports civic administration and consequential story scenes without exposing legal,
family, business, or identity records in the background art.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Port Alder City Hall destination in grounded mature cinematic contemporary realism. Match the supplied reference's practical coastal-city civic architecture, rain-softened late-August daylight, cream civic stone, charcoal slate, warm cedar, muted teal upholstery, dark metal, frosted glass, restrained abstract panels, warm practical lighting, privacy features, and accessible circulation. Preserve the authored route, clear character staging, floating-arrow placement, and an uncluttered lower region for dialogue UI. Keep the building welcoming and serious without ornate governmental grandeur. No people or reflections of people, character sprites, navigation arrows, interface, readable building names, directories, notices, licenses, permits, forms, legal or family records, case or queue numbers, letters, numbers, logos, trademarks, captions, flags, seals, emblems, portraits, statues, or watermark; all screens, signs, forms, folders, and panels must be blank or abstract.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Public Lobby | `port_alder_city_hall/public_lobby.png` | Street-facing civic foyer with reception, waiting seats, blank information panels, accessible security check-in, Civic Square exit, and Licensing route. |
| Licensing Office | `port_alder_city_hall/licenses.png` | Municipal service room with accessible counters, blank queue displays, writing stations, secure staff storage, and routes between Lobby and Family Services. |
| Family Services Desk | `port_alder_city_hall/family_services.png` | Supportive semi-private consultation area with reception, waiting nook, closed records, child-friendly corner, and routes between Licensing and Hearing. |
| Hearing Room | `port_alder_city_hall/hearing_room.png` | Modest administrative chamber with three-seat panel desk, clerk station, consultation tables, public seating, acoustic panels, and one return route. |

### Port Alder Realty batch prompt set

This batch completes all three mapped Port Alder Realty destinations. Civic Square
anchors the rain-darkened street entrance and the Harbor View Condominiums art informs
the attainable residential finish of the Listing Gallery. That gallery establishes a
consistent independent-agency identity for private consultations in the Agent Office
and consequential rental or purchase agreements in the appointment-only Closing Room.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Port Alder Realty destination in grounded mature cinematic contemporary realism. Match the supplied reference's approachable independent housing-agency design, rain-softened late-August Pacific Northwest daylight, warm cedar, muted teal, cream plaster and stone, charcoal slate, dark metal, frosted glass, restrained rust accents, warm practical lighting, quality attainable furnishings, privacy features, and accessible circulation. Preserve the authored route, clear character staging, floating-arrow placement, and an uncluttered lower region for dialogue UI. Keep the business polished and aspirational without luxury excess. No people or reflections of people, character sprites, navigation arrows, interface, readable agency names, property addresses, listings, prices, phone numbers, client names, contracts, floor-plan labels, key tags, calendar dates, mortgage rates, letters, numbers, logos, trademarks, captions, portraits, or watermark; all screens, listings, documents, brochures, folders, tablets, and panels must be blank or abstract.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Listing Gallery | `port_alder_realty/listing_gallery.png` | Civic Square-facing property gallery with reception, consultation seating, blank displays, scale-model and material table, kiosk, and Agent Office route. |
| Agent Office | `port_alder_realty/agent_office.png` | Confidential consultation office with desk, visitor chairs, discussion table, secure records and keys, abstract displays, and routes between Gallery and Closing. |
| Closing Room | `port_alder_realty/closing_room.png` | Private conference room with six seats, blank documents, signature tablet, display, secure storage, water counter, and one Agent Office return. |

### Harbor Centre Business Services batch prompt set

This batch completes all four mapped workplace destinations. The downtown Employment
Block anchors the public Lobby and rainy street entrance. The Lobby establishes the
company's practical commercial palette and controlled-access design for the Open
Office, Meeting Room, and employee-only Break Room. The route supports interviews,
regular shifts, promotions, coworker relationships, and workplace story arcs.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Harbor Centre Business Services destination in grounded mature cinematic contemporary realism. Match the supplied reference's credible mid-sized Pacific Northwest workplace, rain-softened late-August daylight, charcoal stone and flooring, warm cedar, muted teal, cream acoustic surfaces, dark metal, clear and frosted glass, restrained rust accents, warm practical lighting, durable commercial furniture, privacy features, and accessible circulation. Preserve the authored route, access level, clear character staging, floating-arrow placement, and an uncluttered lower region for dialogue UI. Keep the workplace professional and comfortable without corporate luxury. No people or reflections of people, character sprites, navigation arrows, interface, readable company names, directories, client or employee data, schedules, notices, badges, documents, labels, letters, numbers, logos, trademarks, captions, portraits, or watermark; all signs, screens, boards, folders, papers, parcels, packages, calendars, and panels must be blank or abstract.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Lobby | `harbor_business_services/lobby.png` | Employment Block-facing public reception with waiting seats, blank check-in tablet and directory panels, access gates, parcel shelf, and Open Office route. |
| Open Office | `harbor_business_services/open_office.png` | Controlled-access workspace with clustered desks, blank monitors, acoustic dividers, collaboration table, printer, storage, and routes between Lobby and Meeting Room. |
| Meeting Room | `harbor_business_services/meeting_room.png` | Glass-walled eight-seat conference room with powered-off display, blank presentation panels, video camera, storage, and routes between Open Office and Break Room. |
| Break Room | `harbor_business_services/break_room.png` | Employee-only kitchenette and lounge with dining tables, soft seating, lockers, blank vending machine, waste station, rainy window, and one Meeting Room return. |

### Cypress Hall Dorm batch prompt set

This batch completes all seven mapped Cypress Hall destinations. Westshore Campus's
Transit Loop anchors the rainy dorm entrance, while the existing Student Lounge
establishes the college palette. The dorm Lobby defines the residence architecture;
the Study Lounge becomes its navigation hub for the Kitchen, Laundry, Bathroom, and
private housing. Maya's room reflects her disciplined pre-med studies, while the
rentable room remains neutral so it can become the player's college home.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Cypress Hall Dorm destination in grounded mature cinematic contemporary realism. Match the supplied reference's attainable adult college residence, rain-softened late-August Pacific Northwest daylight, warm cedar, muted teal, cream walls or tile, charcoal resilient flooring and counters, dark metal, glass, acoustic panels, restrained rust accents, warm practical lighting, durable student-grade furniture, privacy features, and accessible circulation. Preserve the authored route and access level, clear character staging, floating-arrow placement, and an uncluttered lower region for dialogue UI. Keep the residence safe, ordinary, social, and well maintained rather than luxurious. No people or reflections of people, character sprites, navigation arrows, interface, readable dorm or resident names, room numbers, notices, schedules, prices, course notes, book titles, package or appliance labels, letters, numbers, logos, trademarks, captions, portraits, or watermark; all signs, boards, books, folders, papers, packages, machines, and screens must be blank or abstract.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Lobby | `cypress_hall_dorm/lobby.png` | Transit-facing secure entrance with reception, waiting seats, blank noticeboards, parcel and mail area, access control, elevator, and Study Lounge route. |
| Study Lounge | `cypress_hall_dorm/study_lounge.png` | Central study hub with shared tables, carrels, reading chairs, blank boards, storage, and distinct routes to Lobby, Kitchen, Laundry, and Bathroom. |
| Shared Kitchen | `cypress_hall_dorm/shared_kitchen.png` | Two-station communal kitchen with island, dining table, storage, basic cookware, waste station, rainy window, and one Study Lounge return. |
| Laundry Room | `cypress_hall_dorm/laundry.png` | Communal washers and dryers with blank displays, folding counters, sink, carts, drying rail, kiosk, storage, and one Study Lounge return. |
| Shared Bathroom | `cypress_hall_dorm/shared_bathroom.png` | Privacy-conscious all-gender facility with fully enclosed toilet and shower-changing cubicles, accessible fixtures, sinks, benches, and routes to housing and Lounge. |
| Maya's Shared Room | `cypress_hall_dorm/maya_room.png` | Invitation-only two-student room with beds, desks, wardrobes, organized pre-med study objects, neutral roommate side, and Bathroom route. |
| Rentable Dorm Room | `cypress_hall_dorm/available_room.png` | Neutral single-occupancy furnished room with bed, desk, wardrobe, storage, mini-fridge, campus window, and right-side Bathroom route. |

### Maple Hall Dorm batch prompt set

This batch completes all seven mapped Maple Hall destinations. Westshore Campus's
Transit Loop and the completed Cypress Hall Lobby anchor campus continuity, while the
new Maple Lobby introduces a more casual social identity with restrained burgundy and
rust accents. The Game Lounge becomes the navigation hub for the Kitchen, Laundry,
Bathroom, and housing routes. Theo's room reflects his computing, repair, gaming,
privacy, and practical habits without exposing private identity details; the rentable
room remains neutral for player customization.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Maple Hall Dorm destination in grounded mature cinematic contemporary realism. Match the supplied reference's attainable adult college residence, rain-softened late-August Pacific Northwest daylight, warm cedar, muted teal, cream walls or tile, charcoal resilient flooring and counters, dark metal, glass, restrained rust and burgundy accents, warm practical lighting, durable student-grade furniture, privacy features, and accessible circulation. Preserve the authored route and access level, clear character staging, floating-arrow placement, and an uncluttered lower region for dialogue UI. Keep Maple Hall safe, ordinary, social, well maintained, and more casual than academically focused Cypress Hall. No people or reflections of people, character sprites, navigation arrows, interface, readable dorm or resident names, room numbers, notices, schedules, prices, course notes, book or game titles, package or appliance labels, letters, numbers, logos, trademarks, captions, portraits, or watermark; all signs, boards, books, folders, papers, packages, machines, and screens must be blank or abstract.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Lobby | `maple_hall_dorm/lobby.png` | Transit-facing secure entrance with residence desk, seating, parcel and mail storage, access control, elevator, and Game Lounge route. |
| Game Lounge | `maple_hall_dorm/game_lounge.png` | Central four-way social hub with seating, board-game table, powered-off television and consoles, foosball, and routes to Lobby, Kitchen, Laundry, and Bathroom. |
| Shared Kitchen | `maple_hall_dorm/shared_kitchen.png` | Two-station communal kitchen with prep island, dining table, storage, waste station, and one Game Lounge return. |
| Laundry Room | `maple_hall_dorm/laundry.png` | Communal washers and dryers with folding counters, utility sink, baskets, bench, and one Game Lounge return. |
| Shared Bathroom | `maple_hall_dorm/shared_bathroom.png` | Privacy-conscious all-gender facility with fully enclosed toilet and shower cubicles, sinks, grooming counter, benches, and routes to housing and Lounge. |
| Theo's Shared Room | `maple_hall_dorm/theo_room.png` | Invitation-only two-student room with beds, desks, wardrobes, powered-off computer setup, organized electronics-repair tools, neutral roommate side, and left-side Bathroom route. |
| Rentable Dorm Room | `maple_hall_dorm/available_room.png` | Neutral single-occupancy furnished room with bed, desk, wardrobe, storage, mini-fridge, campus window, and right-side Bathroom route. |

### Westshore Shared Student Apartment batch prompt set

This batch completes all seven mapped destinations in the hidden-until-invited-or-leased
shared apartment. Westshore Campus's Transit Loop establishes the rainy college-district
continuity, while the Apartment Entry defines a warmer private-home palette. The Living
Room becomes the four-way household hub for the Entry, Chloe's Bedroom, Kitchen, and
Balcony; the Kitchen continues to the rentable room and Bathroom. Chloe's room expresses
her illustration, fashion, and freelance work without revealing private identity details,
while the rentable bedroom remains neutral for player customization.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Westshore Shared Student Apartment destination in grounded mature cinematic contemporary realism. Match the supplied reference's modest private adult-student home, rain-softened late-August Pacific Northwest daylight, warm natural oak, cream plaster or tile, charcoal, sage, muted teal, restrained dusty rose and ochre accents, dark metal, warm household lighting, ordinary student-owned furniture, plants, creative details, privacy features, and accessible circulation. Preserve the authored route and access level, clear character staging, floating-arrow placement, and an uncluttered lower region for dialogue UI. Keep the home youthful, expressive, safe, attainable, lived-in, and clearly less institutional than the dorms without becoming luxurious. No people or reflections of people, character sprites, navigation arrows, interface, readable resident names, addresses, unit numbers, schedules, prices, notes, book or game titles, food or appliance labels, private documents, letters, numbers, logos, trademarks, captions, portraits, identity slogans, or watermark; all signs, boards, books, folders, papers, packages, machines, and screens must be blank or abstract.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Apartment Entry | `westshore_shared_student_apartment/entry.png` | Secure private foyer with bench, coat and shoe storage, umbrella stand, rainy campus glimpse, exterior door, and right-side Living Room route. |
| Living Room | `westshore_shared_student_apartment/living_room.png` | Central four-way shared-home hub with mismatched seating, blank television, creative details, and routes to Entry, Chloe's Bedroom, Kitchen, and Balcony. |
| Kitchen | `westshore_shared_student_apartment/kitchen.png` | Compact shared kitchen with island, storage, ordinary appliances, and distinct routes to Living Room, Rentable Bedroom, and Bathroom. |
| Chloe's Bedroom | `westshore_shared_student_apartment/chloe_bedroom.png` | Invitation-only creative room with bed, wardrobe, clothing rack, illustration workstation, blank screens, art materials, abstract work, and one Living Room return. |
| Rentable Bedroom | `westshore_shared_student_apartment/available_bedroom.png` | Neutral private room with full bed, desk, wardrobe, dresser, empty storage, rainy window, and one Kitchen return. |
| Bathroom | `westshore_shared_student_apartment/bathroom.png` | Full shared bathroom with closed tub-shower, double vanity, toilet, storage, frosted window, and one Kitchen return. |
| Balcony | `westshore_shared_student_apartment/balcony.png` | Covered rainy balcony with safe railing, shared seating, planters, storage bench, college-district view, and one Living Room return. |

### Westshore Bookshop batch prompt set

This batch completes both mapped daytime destinations in Westshore's weekday campus
bookshop. The Westshore Campus Cafeteria establishes the adjacent architecture, daylight,
and left-side arrival route, while the Campus Library anchors believable shelving and the
book-oriented visual language. The Sales Floor establishes the store palette and leads
right to the Service Counter, which has one clear route back to the Sales Floor.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Westshore Bookshop destination in grounded mature cinematic contemporary realism. Match the supplied Westshore Campus references' weekday daylight, dark cedar wood, charcoal slate, muted teal, warm cream, restrained rust accents, matte metal, paper goods, subdued commercial flooring, and practical accessible circulation. Preserve the authored route, clear character staging, and an uncluttered lower and central foreground for dialogue sprites. Keep the campus store compact, welcoming, functional, attainable, and visually continuous with the Cafeteria and Library. No people or reflections of people, character sprites, navigation arrows, interface, readable titles, course codes, prices, receipts, labels, signs, words, letters, numbers, logos, trademarks, brands, mannequins, human-shaped displays, or watermark; all books, papers, products, machines, and screens must be blank, abstract, or powered off.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Sales Floor | `westshore_bookshop/sales_floor.png` | Public textbook and school-supply store with browsing shelves and tables, blank kiosk, left Cafeteria return, and right Service Counter route. |
| Service Counter | `westshore_bookshop/service_counter.png` | Checkout, returns, pickup, and employee-service area with blank POS, organized cubbies and storage, impulse supplies, and one Sales Floor return. |

### Lantern Gallery batch prompt set

This batch completes all four mapped destinations in Lantern Gallery's public arts,
event, and appointment route. Westshore's Art Studios and Chloe's Bedroom provide
creative-material continuity, while the Galleria Event Space establishes flexible event
infrastructure. The Main Gallery defines Lantern Gallery's restored-brick identity and
connects the street, Student Wall, and Event Room; the Event Room continues to the
employee-or-appointment-only Gallery Office.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Lantern Gallery destination in grounded mature cinematic contemporary realism. Match the supplied Port Alder references while giving the independent gallery its own restored urban storefront identity: cream plaster, selective aged red brick, warm cedar trim, blackened steel, dark polished concrete, professional track lighting, rain-softened late-afternoon coastal daylight, amber practical light, muted burgundy, deep teal, and restrained ochre. Preserve the authored route and access level, clear character staging, and an uncluttered lower and central foreground for dialogue sprites. Keep the gallery intimate, cultured, welcoming, accessible, attainable, and suitable for exhibitions, dates, networking, events, and employment stories. No people or reflections of people, character sprites, navigation arrows, interface, readable exhibit labels, artist or school names, event posters, schedules, prices, contracts, signs, words, letters, numbers, logos, trademarks, brands, captions, mannequins, human-shaped sculpture, recognizable real artworks, copyrighted art, portraits, or watermark; all screens, papers, folders, boards, and wall cards must be blank, abstract, closed, or powered off, and all displayed art must be original, abstract, tasteful, non-graphic, and free of legible symbols or text.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Main Gallery | `lantern_gallery/main_gallery.png` | Public exhibition hub with abstract paintings and sculpture, reception pedestal, benches, street entry, rear Event Room route, and right Student Wall route. |
| Student Wall | `lantern_gallery/student_wall.png` | Intimate emerging-artist exhibition room with varied abstract student work, protected sketchbooks, ceramics, seating, and one Main Gallery return. |
| Event Room | `lantern_gallery/event_room.png` | Flexible talk, workshop, opening, and reception room with blank projection surface, modular platform, chairs, stored tables, refreshment counter, Main Gallery return, and right Office route. |
| Gallery Office | `lantern_gallery/office.png` | Private curator workspace with blank computer, visitor chairs, flat files, archival storage, art-handling materials, abstract samples, and one Event Room return. |

### Lantern District Street batch prompt set

This batch completes all three mapped outdoor hubs in the Lantern District's walkable
entertainment route. Harborlight Cinema and Lantern Gallery anchor their matching public
entrances, while the newly established Cinema Block defines the district's restored-brick,
wet-pavement, tree-lined streetscape. Restaurant Lane becomes the four-way hub for dining,
nightlife, and east-west movement; Gallery Walk joins the arts destination to the
privacy-conscious cooperative route.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Lantern District Street destination in grounded mature cinematic contemporary realism. Match the supplied Port Alder references while giving the district a coherent walkable entertainment-neighborhood identity: restored low-rise aged-red-brick buildings, dark cedar, charcoal and black metal, muted teal, warm cream, burgundy, restrained amber, broad accessible stone sidewalks, mature trees, planters, benches, bicycle racks, blank canvas awnings, lantern-like streetlights, rain-softened late-afternoon coastal daylight, warm storefront light, and wet-pavement reflections. Preserve the authored route, clear character staging, and a generous uncluttered lower and central foreground for dialogue sprites and floating navigation controls. Keep the district safe, mature, inviting, attainable, and empty for sprite staging. No people or reflections of people, character sprites, vehicles, navigation arrows, interface, readable venue names, film titles, showtimes, restaurant menus, club advertising, gallery labels, service lists, prices, hours, addresses, street signs, words, letters, numbers, logos, trademarks, brands, captions, recognizable copyrighted characters or artworks, sexualized imagery, adult advertising, or watermark; all marquees, posters, awnings, signs, screens, boards, menus, window cards, display cases, and intercom panels must be blank, abstract, dark, or softly lit without symbols.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Cinema Block | `lantern_district_street/cinema_block.png` | Western district hub with unbranded cinema facade, blank marquee and poster cases, sheltered entrance, wet sidewalk, and right-side continuation to Restaurant Lane. |
| Restaurant Lane | `lantern_district_street/restaurant_lane.png` | Central four-way dining hub with empty covered patios, prominent La Brisa entrance, discreet safe Tideglass entrance, and clear left/right street continuations. |
| Gallery Walk | `lantern_district_street/gallery_walk.png` | Quieter arts-focused route with Lantern Gallery storefront, abstract display windows, benches, and right-side continuation toward the cooperative's secure reception. |

### La Brisa Kitchen batch prompt set

This batch carries Restaurant Lane's prominent restaurant entrance into a complete
public dining-and-date route and a believable employee path. The Dining Room anchors
the interior architecture, its Bar leads into the commercial Kitchen, and the Kitchen
provides the only route to the Manager Office. The sheltered Patio returns directly to
the Dining Room without introducing an exterior shortcut.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped La Brisa Kitchen destination in grounded mature cinematic contemporary realism. Continue the polished but attainable coastal Latin restaurant established by Restaurant Lane and the Dining Room: terracotta, deep ocean blue, cream plaster, dark walnut, black metal, aged brick, patterned ceramic accents, greenery, warm amber practical light, and rain-softened late-afternoon coastal daylight. Preserve the authored room-to-room route and access level, give character sprites a clear lower and central staging area, and keep public, employee, and private spaces visibly distinct. No people or reflections of people, character sprites, navigation arrows, interface, readable menus, labels, schedules, receipts, prices, names, words, letters, numbers, logos, trademarks, brands, cultural stereotypes, sexualized imagery, or watermark; all screens, papers, boards, bottles, containers, binder spines, and signs must be blank, unmarked, closed, dark, or abstract.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Dining Room | `la_brisa_kitchen/dining_room.png` | Public restaurant hub with generous date and meal seating, street return, right-side Bar route, rear Patio route, and clear central staging. |
| Bar | `la_brisa_kitchen/bar.png` | Warm social and service room with unmarked bottles, Dining Room return on the left, Kitchen route at the rear, and space for server scenes. |
| Kitchen | `la_brisa_kitchen/kitchen.png` | Credible commercial line, prep, pass, and dishwashing workspace with a Bar opening and right-side Manager Office route. |
| Manager Office | `la_brisa_kitchen/manager_office.png` | Compact private supervisor workspace with blank planning board and screen, secure storage, visitor chair, and one left return to the Kitchen. |
| Patio | `la_brisa_kitchen/patio.png` | Sheltered brick-and-plaster courtyard with pergola, awning, greenery, date seating, district rooftops, and one return to the Dining Room. |

### Tideglass Club batch prompt set

This batch carries Restaurant Lane's discreet below-street club entrance through a
strict adults-only nightlife route. The Entry leads only to the Dance Floor; the Dance
Floor branches left to the Bar and right to the quieter Lounge; and the Lounge provides
the sole route to the inclusive Restrooms. A targeted Dance Floor edit replaced an
unmapped decorative console with the required visible return to the Entry.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Tideglass Club destination in grounded mature cinematic contemporary realism. Continue the restored-brick shell seen on Restaurant Lane while giving the intimate, attainable nightclub its own identity through smoked and fluted glass, deep petrol teal, muted plum, dark oak, blackened steel, brushed bronze, charcoal stone, controlled abstract ripple lighting, and readable nighttime ambience. Preserve the authored room-to-room route, clear lower and central character staging, accessible circulation, intoxication-aware safety, and a visible distinction between dancing, drink service, quiet conversation, and hygiene spaces. No people or reflections of people, character sprites, navigation arrows, interface, readable signs, menus, prices, labels, names, words, letters, numbers, logos, trademarks, brands, screen content, drugs, weapons, sexualized imagery, audio equipment, or watermark; all bottles, panels, screens, fixtures, and signs must be plain, unmarked, dark, or abstract.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Entry | `tideglass_club/entry.png` | Compact below-street vestibule with blank host pedestal, seating, street return, and one broad opening to the Dance Floor. |
| Dance Floor | `tideglass_club/dance_floor.png` | Clear central dance and sprite-staging floor with a rear Entry return, left Bar opening, right Lounge opening, and restrained ripple ceiling light. |
| Bar | `tideglass_club/bar.png` | Sculptural bronze-and-dark-oak service counter with plain bottles, accessible ordering point, and one right return to the Dance Floor. |
| Lounge | `tideglass_club/lounge.png` | Quieter plum-and-teal conversation room with open Dance Floor return on the left and a short rear route to the Restrooms. |
| Restrooms | `tideglass_club/restrooms.png` | Clean inclusive restroom suite with accessible vanity, closed unmarked privacy compartments, and one visible return to the Lounge. |

### Harbor Companion Cooperative batch prompt set

This batch completes the cooperative's access-controlled adults-only workplace route.
Secure Reception remains a public licensing and safety contact point; the Consultation
Room and Health and Safety Office require appointments; the Staff Lounge is reserved for
licensed workers; and the Private Suite supports only consenting-adult appointments and
strictly non-graphic fade-to-black scenes. Targeted cleanup edits removed generated
symbols and markings from the safety cabinet and private-suite controls.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Harbor Companion Cooperative destination in grounded mature cinematic contemporary realism. Continue Gallery Walk's restored-brick shell while giving this dignified licensed workplace a calm privacy-conscious identity through cream plaster, warm walnut, deep ink blue, muted clay, sage, frosted and fluted glass, brushed bronze, charcoal stone, plants, abstract art, and warm late-afternoon light. Preserve the authored room-to-room route and access level, clear lower and central character staging, accessible circulation, consent, health compliance, confidentiality, worker safety, and the right to refuse. No people or reflections of people, character sprites, navigation arrows, interface, readable service lists, licenses, forms, names, prices, schedules, words, letters, numbers, logos, trademarks, brands, screen content, nudity, sexual activity, suggestive imagery, lingerie, condoms, sex toys, restraints, alcohol, drugs, weapons, or watermark; all screens, papers, boards, cabinets, controls, containers, and signs must be blank, closed, dark, plain, or abstract. Adult-only but strictly non-graphic environmental storytelling.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Secure Reception | `harbor_companion_cooperative/secure_reception.png` | Public privacy-conscious reception with blank desk and document drop, Gallery Walk return, forward Safety Office route, and controlled right Consultation route. |
| Consultation Room | `harbor_companion_cooperative/consultation_room.png` | Neutral three-chair boundary and consent conversation room with Reception return on the left and controlled Private Suite route on the right. |
| Health and Safety Office | `harbor_companion_cooperative/health_and_safety_office.png` | Confidential worker-support office with blank screens and records, unmarked safety storage, Reception return, and right Staff Lounge route. |
| Staff Lounge | `harbor_companion_cooperative/staff_lounge.png` | Ordinary licensed-worker break and peer-support room with kitchenette, seating, unmarked lockers, charging shelf, and one left return. |
| Private Suite | `harbor_companion_cooperative/private_suite.png` | Neutral hospitality suite with opaque made bed, equal seating, water, closed storage, unmarked controls, and one left return to Consultation. |

### Rowan Family Home batch prompt set

This batch establishes the invitation-only neighboring home shared by Emma Rowan and her
parents. The older pale craftsman bungalow visible beside the Hale property anchors an
interior built around honey oak, cream, moss, muted navy, dusty rose, books, and long-kept
family furnishings. The Living Room provides the four-way hub; Emma's attic-level bedroom
remains relationship-permission-only; and the Kitchen, Bathroom, Porch, and enclosed
Backyard preserve the authored routes without shortcuts.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped Rowan Family Home destination in grounded mature cinematic contemporary realism. Continue the older pale craftsman bungalow already visible beside the Hale home, giving the cared-for middle-class residence a cozy slightly eclectic identity through warm cream, soft moss, honey oak, muted navy, dusty rose, charcoal stone, aged brass, plants, well-used books, and rain-softened late-August light. Preserve the authored room-to-room route and invitation or relationship-permission access, give character sprites a clear lower and central staging area, and distinguish shared family spaces from Emma's private room. No people or reflections of people, character sprites, navigation arrows, interface, readable book titles, manuscripts, labels, names, words, letters, numbers, logos, trademarks, brands, screen content, photo faces, sexualized imagery, alcohol, drugs, weapons, or watermark; all books, screens, papers, photos, cards, containers, controls, and signs must be blank, closed, dark, abstract, spine-away, face-down, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Front Porch | `rowan_family_home/porch.png` | Covered older-craftsman porch with garden, bench, right front door to the Living Room, and central steps returning to Hale Block. |
| Living Room | `rowan_family_home/living_room.png` | Cozy four-way family hub with porch return, compact staircase to Emma's room, right Kitchen opening, rear Backyard door, books, and fireplace. |
| Kitchen | `rowan_family_home/kitchen.png` | Gradually renovated family kitchen with moss tile, mixed cabinets, left Living Room opening, and one rear Bathroom doorway. |
| Emma's Bedroom | `rowan_family_home/emma_bedroom.png` | Permission-gated attic room expressing Emma's literature, writing, photography, anxiety, and creativity through unmarked books, desk, reading chair, and one landing return. |
| Bathroom | `rowan_family_home/bathroom.png` | Compact shared bathroom with tub-shower, vanity, ordinary fixtures, folded family towels, and one return to the Kitchen. |
| Backyard | `rowan_family_home/backyard.png` | Enclosed rain-softened garden with patio, reading chairs, raised beds, closed shed, and one rear-door return to the Living Room. |

### Jade's Downtown Condo batch prompt set

This batch establishes Jade Mercer's discoverable, invitation-only private home in Harbor
Centre. The Residential Block, Harbor View Condominiums, and Harbor Companion Cooperative
provide exterior, residential, and character continuity without making the attainable
one-bedroom condo feel like a penthouse or workplace. Deep ink blue, muted plum, smoky
rose, warm walnut, cream, charcoal stone, brushed bronze, and restrained sage express
Jade's composed, elegant, pragmatic, private personality. The Living Room is the four-way
hub; her Bedroom remains relationship-permission-only; and the Office supports budgeting,
administration, safety planning, cooperative development, and her financial exit plan. A
targeted Living Room edit added the distinct foreground Office doorway while preserving
the Entry, Bedroom, and Kitchen routes.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination in Jade Mercer's secure one-bedroom downtown condo in grounded mature cinematic contemporary realism. The condo belongs to a composed, elegant, pragmatic, private 25-year-old professional with strong boundaries, a business certificate, and a careful financial exit plan. Keep the home tasteful, controlled, attainable, lived in, and separate from her workplace rather than luxurious, sterile, sexualized, or hotel-like. Use deep ink blue, muted plum, smoky rose, warm walnut, cream, charcoal stone, brushed bronze, restrained sage, rain-softened Harbor Centre daylight, and warm practical lighting. Preserve exactly the authored room-to-room routes and access level, provide a generous uncluttered lower and central character-staging area, and keep fixed skyline windows from implying an unmapped balcony. No people or reflections of people, character sprites, navigation arrows, interface, readable books, records, client data, schedules, labels, names, addresses, words, letters, numbers, logos, trademarks, brands, screen content, photo faces, nudity, sexualized imagery, lingerie, suggestive objects, alcohol, drugs, weapons, cash, or watermark; all screens must be dark and all panels, papers, folders, containers, and boards must be blank, closed, face-down, secured, plain, or abstract.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Secure Entry | `jade_downtown_condo/entry.png` | Controlled private foyer with substantial unit door, blank intercom, coat and shoe storage, and one right opening into the Living Room. |
| Living Room | `jade_downtown_condo/living_room.png` | Four-way hub with distinct Entry, Bedroom, Kitchen, and foreground Office routes, rainy fixed skyline windows, restrained seating, and no balcony door. |
| Kitchen | `jade_downtown_condo/kitchen.png` | Compact capable kitchen with walnut cabinetry, charcoal counters, two-seat dining ledge, left Living Room opening, and one rear Bathroom doorway. |
| Bedroom | `jade_downtown_condo/bedroom.png` | Permission-gated private room with opaque made bed, closed storage, reading chair, blackout curtains, fixed city window, and one Living Room return. |
| Bathroom | `jade_downtown_condo/bathroom.png` | Practical cream, charcoal, and walnut room with fluted-glass tub-shower, ordinary fixtures, folded towels, and one Kitchen return. |
| Home Office | `jade_downtown_condo/office.png` | Confidential planning room with practical desk, equal visitor chairs, dark screens, secure records, blank planning board, and one Living Room return. |

### Greyport Main Street batch prompt set

This batch establishes Greyport's discoverable outdoor district spine and its identity as
an affordable, industrial, transit-oriented working waterfront with long-standing housing
and late-night music. The Apartment Block anchors the four-way hub between the Bus
Exchange, two residential lanes, and Industrial Corner. Unmarked family and shared-housing
doors remain visible without revealing invitation-gated residents, while Industrial Corner
separates the distribution warehouse, transit depot, and Undertow approach. Weathered
brick, faded blue-gray, muted industrial green, galvanized steel, dark cedar, repaired wet
paving, restrained rust, amber practical light, and resident-tended greenery keep Greyport
grounded, resilient, safe, and cared for rather than luxurious, dystopian, or stereotyped.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination along Greyport Main Street in grounded mature cinematic contemporary realism. Greyport is a safe, lived-in Pacific Northwest coastal working district where affordable brick housing, practical transit infrastructure, warehouses, repair work, and independent late-night music coexist. Keep it slightly gritty but cared for, resilient, accessible, communal, and attainable rather than a slum, dystopia, luxury district, abandoned zone, or crime stereotype. Use weathered red and umber brick, faded blue-gray paint, muted industrial green, galvanized steel, charcoal asphalt and concrete, dark cedar, restrained rust, mossy resident-tended greenery, rain-softened late-August light, and warm practical amber fixtures. Preserve exactly the authored outdoor routes through distinct building masses, curbs, paving, sightlines, entrances, and lighting, with a generous uncluttered lower and central staging area for character sprites. Private residences remain unmarked for discovery gating. No people or reflections of people, character sprites, vehicles, navigation arrows, interface, readable transit information, employer or venue names, addresses, signs, notices, schedules, prices, advertisements, posters, graffiti words, words, letters, numbers, logos, trademarks, brands, screen content, weapons, drugs, visible crime, hazardous spills, broken windows, garbage piles, stereotypes, sexualized imagery, or watermark; all signs, panels, awnings, doors, windows, and poster cases must be blank, closed, dark, abstract, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Greyport Bus Exchange | `greyport_street/bus_exchange.png` | Modest waterfront bus bays, blank shelters and route panels, benches, tactile paving, taxi curb, and one right continuation toward the Apartment Block. |
| Apartment Block | `greyport_street/apartment_block.png` | Four-way neighborhood hub with left Bus Exchange route, rear North Residential Lane, right Industrial Corner street, foreground South Residential Lane, and an unmarked studio-building entrance. |
| North Residential Lane | `greyport_street/north_residences.png` | Narrow cared-for brick lane with one upper Lee-family entrance, one right Donovan-family entrance, resident planters, and foreground return to the Apartment Block. |
| South Residential Lane | `greyport_street/south_residences.png` | Mixed-density lane with one left Flores-townhouse entrance, one right shared-apartment entrance, and rear return to the Apartment Block. |
| Industrial Corner | `greyport_street/industrial_corner.png` | Four-way working junction with left housing return, rear controlled warehouse entry, right transit-depot public entrance, and foreground descent into Nightlife Alley. |
| Nightlife Alley | `greyport_street/nightlife_alley.png` | Safe blue-hour converted-warehouse alley with rear Industrial Corner return and one right Undertow entrance using abstract teal-and-plum accents. |

### Lee Family Apartment batch prompt set

This batch carries North Residential Lane's upper invitation-only entrance into the
compact family apartment shared by Marcus Lee, a parent, and an unnamed adult cousin. The
home is long-lived, affordable, practical, safe, and cared for, using warm cream plaster,
aged honey oak, faded ocean blue trim, forest green, muted burnt orange, charcoal, and
blackened metal. Shared rooms mix inherited furniture with sensible updates, while
Marcus's room expresses his filmmaking, humor, big plans, unfinished short film, and
creative disorganization through dark editing screens, blank storyboard cards, camera
equipment, and closed media storage. The cousin's room remains restricted, anonymous, and
free of invented identity or biography.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside the invitation-only Lee Family Apartment in grounded mature cinematic contemporary realism. Continue the older Greyport brick walk-up seen on North Residential Lane and make the compact home feel long-lived, practical, safe, affordable, welcoming, and cared for rather than luxurious, shabby, student-only, culturally stereotyped, or overdecorated. Use warm cream plaster, aged honey oak, faded ocean blue trim and tile, forest green, muted burnt orange, charcoal, blackened metal, restrained amber practical light, and rain-softened fixed windows. Preserve exactly the authored room-to-room routes and access level with a generous uncluttered lower and central character-staging area. Shared rooms serve three adults; Marcus's invitation-only room may show affordable filmmaking and editing tools; the cousin's restricted room must remain deliberately neutral and private. No people or reflections of people, character sprites, navigation arrows, interface, readable mail, books, scripts, storyboards, calendars, labels, names, addresses, movie titles, copyrighted posters or characters, words, letters, numbers, logos, trademarks, brands, photo faces, active screen content, religious or cultural stereotypes, nudity, sexualized imagery, underwear, alcohol, drugs, weapons, garbage piles, broken fixtures, or watermark; all screens must be dark and all papers, storage, containers, and boards must be blank, closed, face-down, plain, abstract, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Apartment Door | `lee_family_apartment/front_door.png` | Shallow threshold with exterior landing return on the left, right Living Room opening, shoe bench, coat hooks, umbrella stand, old radiator, and blank mail tray. |
| Living Room | `lee_family_apartment/living_room.png` | Three-way family hub with left Entry, rear Marcus Bedroom, right Kitchen, mismatched cared-for seating, compact dining table, dark television, and closed film gear. |
| Kitchen | `lee_family_apartment/kitchen.png` | Gradually updated honey-oak family kitchen with left Living Room opening, rear Bathroom doorway, three-person eating space, and ordinary practical appliances. |
| Marcus's Bedroom | `lee_family_apartment/marcus_bedroom.png` | Invitation-only creative room with bed, dark dual-monitor editing desk, blank storyboard cards, camera and tripod, spine-away books, gear cases, and one Living Room return. |
| Cousin's Bedroom | `lee_family_apartment/cousin_bedroom.png` | Restricted neutral adult room with made bed, closed storage, closed laptop, abstract art, fixed rainy window, and no invented identity clues. |
| Bathroom | `lee_family_apartment/bathroom.png` | Shared cream-and-blue bathroom with tub-shower, ordinary fixtures, three towel sets, old radiator, plain toiletries, and one Kitchen return. |

### Flores Family Townhouse batch prompt set

This batch carries South Residential Lane's invitation-only entrance into the narrow
older brick townhouse shared by Nadia Flores, her mother, and her grandmother. The home
is safe, affordable, multigenerational, and visibly cared for, using warm cream, soft
terracotta, sea-glass teal, honey oak, deep olive, charcoal, aged brass, and muted plum.
Shared rooms support practical family life and Nadia's demanding study-and-care schedule.
Her room emphasizes nursing study, competence, fatigue, and rest without romance cues.
The grandmother's restricted room remains dignified, private, identity-neutral, and free
of invented health, disability, religion, culture, hobby, or biography details.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside the invitation-only Flores Family Townhouse in grounded mature cinematic contemporary realism. Continue the narrow older Greyport brick townhouse seen on South Residential Lane and make the multigenerational home feel safe, practical, affordable, welcoming, and carefully maintained rather than luxurious, shabby, clinical, culturally stereotyped, or overdecorated. Use warm cream, soft terracotta, sea-glass teal, honey oak, deep olive, charcoal, aged brass, muted plum, warm practical amber light, and rain-softened fixed windows. Preserve exactly the authored room-to-room routes and access level with a generous uncluttered lower and central character-staging area. Nadia's invitation-only bedroom may show nursing study and care-work demands with dark screens and closed blank materials; the grandmother's restricted room must remain dignified, private, neutral, and free of invented health or identity clues. No people or reflections of people, character sprites, navigation arrows, interface, readable books, study cards, calendars, labels, names, addresses, medical diagrams, prescriptions, medication, medical equipment, blood, diagnoses, copyrighted art or characters, words, letters, numbers, logos, trademarks, brands, photo faces, active screen content, religious or cultural stereotypes, nudity, sexualized imagery, underwear, alcohol, drugs, weapons, garbage piles, broken fixtures, or watermark; all screens must be dark and all papers, storage, containers, and boards must be blank, closed, face-down, plain, abstract, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Front Door | `flores_family_townhouse/front_door.png` | Shallow townhouse threshold with left/down exterior return to South Residential Lane, right Living Room opening, practical coat-and-shoe storage, and exactly those two routes. |
| Living Room | `flores_family_townhouse/living_room.png` | Four-way family hub with left Front Door, upper stairs toward Nadia's Bedroom, right Kitchen, rear glazed Small Yard door, cared-for seating, and quiet multigenerational details. |
| Kitchen | `flores_family_townhouse/kitchen.png` | Practical honey-oak family kitchen with left Living Room opening, rear/right Bathroom door, shared table, ordinary appliances, and exactly those two routes. |
| Nadia's Bedroom | `flores_family_townhouse/nadia_bedroom.png` | Invitation-only nursing student's room balancing study and rest, with dark laptop, closed blank study materials, practical work bag, bed, storage, and one Living Room return. |
| Grandmother's Room | `flores_family_townhouse/grandmother_room.png` | Restricted dignified older adult's room with comfortable bed and chair, closed storage, abstract art, fixed rainy window, closed privacy door, and no invented identity or health clues. |
| Bathroom | `flores_family_townhouse/bathroom.png` | Shared cream-and-teal family bathroom with tub-shower, ordinary fixtures, subtle universal-design grab rail, practical storage, and one Kitchen return. |
| Small Yard | `flores_family_townhouse/small_yard.png` | Compact enclosed rain-softened yard with tended containers, simple seating, brick boundary, and one rear door returning to the Living Room. |

### Greyport Shared Apartment batch prompt set

This batch carries South Residential Lane's hidden shared-apartment entrance into an
affordable two-bedroom rental accessible by Sofia's invitation or the player's lease.
The converted older brick-and-corrugated-metal building is warm, social, practical, and
carefully maintained, using warm cream, selective weathered brick, paprika, muted wine
red, deep teal, mustard, dark walnut, charcoal metal, and aged brass. Sofia's private room
expresses restaurant leadership, business ambition, playful confidence, and the need for
rest without using her surname, orientation, relationships, or private preferences as
visual shorthand. The rentable bedroom remains neutral and ready for player customization.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside the hidden invitation-or-lease Greyport Shared Apartment in grounded mature cinematic contemporary realism. Continue the affordable converted older brick-and-corrugated-metal building on South Residential Lane and make the two-bedroom rental feel safe, energetic, practical, attainable, welcoming, and carefully maintained rather than luxurious, shabby, student-dorm-like, culturally themed, or overdecorated. Use warm cream, selective weathered red brick, paprika, muted wine red, deep teal, mustard, dark walnut, charcoal metal, aged brass, rain-softened late-August daylight, and warm practical amber light. Preserve exactly the authored room-to-room routes and access level with all exits visibly separate and a generous uncluttered central and lower character-staging area. Sofia's invitation-only room may express restaurant leadership, cooking, dancing, business ambition, and rest through dark screens and closed blank materials without sexual or cultural cues; the lease-only available bedroom must remain neutral and customizable. No people or reflections of people, character sprites, navigation arrows, interface, readable schedules, mail, books, menus, recipes, labels, names, addresses, signs, prices, posters, words, letters, numbers, logos, trademarks, brands, photo faces, active screen content, flags, religious symbols, cultural stereotypes, nudity, sexualized imagery, underwear, alcohol, drugs, weapons, garbage piles, broken fixtures, luxury finishes, or watermark; all screens must be dark and all papers, storage, containers, and boards must be blank, closed, face-down, plain, abstract, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Apartment Entry | `greyport_shared_apartment/entry.png` | Shallow private threshold with one charcoal exterior door returning to South Residential Lane, one right Living Room opening, fixed rain window, shoe bench, coat hooks, umbrella stand, and no extra exterior passage. |
| Living Room | `greyport_shared_apartment/living_room.png` | Three-way shared social hub with left Entry, upper-rear Sofia Bedroom, right Kitchen, modest seating and dining furniture, dark television, and no extra exit. |
| Kitchen | `greyport_shared_apartment/kitchen.png` | Practical deep-teal kitchen with three visibly separate routes: left Living Room, far-right Available Bedroom, near-right Bathroom, plus ordinary appliances and a two-person breakfast surface. |
| Sofia's Bedroom | `greyport_shared_apartment/sofia_bedroom.png` | Invitation-only personal room with wine-red and teal bedding, dark laptop, closed blank hospitality and business-planning materials, plain apron, stored dance shoes, closed wardrobe, and one Living Room return. |
| Available Bedroom | `greyport_shared_apartment/available_bedroom.png` | Lease-only move-in-ready room with neutral bed, dresser, closed wardrobe, desk, empty shelf, fixed rainy window, no occupant-specific identity clues, and one Kitchen return. |
| Bathroom | `greyport_shared_apartment/bathroom.png` | Compact shared cream-and-teal bathroom with tub-shower, ordinary fixtures, two towel colors, closed storage, plain toiletries, radiator, and one Kitchen return. |

### Donovan Family Apartment batch prompt set

This batch carries North Residential Lane's invitation-only entrance into the compact
apartment shared by Claire Donovan and her unnamed adult mother. The home is tightly
budgeted, long-lived, private, dignified, resilient, and carefully maintained, using warm
gray, cream, cool denim blue, smoky lavender, faded dusty rose, restrained rust, honey
maple, charcoal metal, and aged brass. Claire's room expresses retail and fashion skill,
beginner photography, paused college plans, careful budgeting, guarded independence, and
the hope of moving forward without exposing her private relationship preferences. The
mother's restricted room remains deliberately neutral and free of invented identity.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside the hidden invitation-only Donovan Family Apartment in grounded mature cinematic contemporary realism. Continue the compact older apartment above Greyport's North Residential Lane and make the two-adult family home feel tightly budgeted, long-lived, private, practical, dignified, resilient, safe, and carefully maintained rather than luxurious, shabby, student-only, stereotyped, or a poverty caricature. Use warm gray and cream plaster, cool denim blue, smoky lavender, faded dusty rose, restrained rust, honey maple, charcoal metal, aged brass, rain-softened late-August daylight, and warm practical lamps. Preserve exactly the authored room-to-room routes and access level with all exits visibly separate and a generous uncluttered central and lower character-staging area. Claire's invitation-only room may express retail, fashion, budgeting, photography, paused college plans, independence, and trust through tasteful everyday outerwear, a dark laptop, simple camera, and closed blank materials without sexual cues; the mother's restricted room must remain dignified, private, and identity-neutral. No people or reflections of people, character sprites, navigation arrows, interface, readable bills, bank papers, schedules, mail, books, college forms, labels, names, addresses, signs, prices, posters, words, letters, numbers, logos, trademarks, brands, photo faces, active screen content, flags, religious symbols, cultural stereotypes, nudity, sexualized imagery, underwear, alcohol, drugs, weapons, garbage piles, broken fixtures, visible financial-distress caricature, luxury finishes, or watermark; all screens must be dark and all papers, storage, containers, and boards must be blank, closed, face-down, plain, abstract, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Apartment Door | `donovan_family_apartment/front_door.png` | Private threshold with one charcoal exterior door returning to North Residential Lane, one right Living Room opening, fixed rainy window, two-person outerwear storage, umbrella stand, radiator, and no extra passage. |
| Living Room | `donovan_family_apartment/living_room.png` | Three-way family hub with left Front Door, upper-rear Claire Bedroom, right Kitchen, cared-for denim seating, refurbished maple furniture, dark television, and no extra exit. |
| Kitchen | `donovan_family_apartment/kitchen.png` | Gradually refreshed cream-and-denim kitchen with left Living Room opening, lower-side Bathroom doorway, ordinary appliances, two-person table, and exactly those two routes. |
| Claire's Bedroom | `donovan_family_apartment/claire_bedroom.png` | Invitation-only adult room with denim and smoky-lavender bedding, tasteful everyday clothing rail, dark laptop, simple camera, closed blank college and budget materials, mirror, closed wardrobe, and one Living Room return. |
| Mother's Bedroom | `donovan_family_apartment/mother_bedroom.png` | Restricted neutral adult room with made bed, comfortable chair, closed storage, fixed rainy window, restrained abstract art, one closed privacy door, and no invented identity or health clues. |
| Bathroom | `donovan_family_apartment/bathroom.png` | Shared cream, denim, and dusty-rose bathroom with tub-shower, ordinary fixtures, closed storage, plain toiletries, radiator, and one clear Kitchen return. |

### Greyport Distribution batch prompt set

This batch carries Greyport Industrial Corner's controlled warehouse entrance through a
safe, regulated workplace supporting interviews, warehouse employment, physical job
requirements, inventory development, performance, and promotion. The restored industrial
interior uses weathered umber brick, muted industrial green, galvanized steel, charcoal
concrete, navy accents, restrained safety amber, and warm cedar. It feels active,
organized, accessible, humane, and hard-working rather than dangerous, abandoned,
dystopian, prison-like, or excessively automated.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside Greyport Distribution in grounded mature cinematic contemporary realism. Continue the restored brick-and-corrugated industrial complex on Greyport's Industrial Corner and make the distribution workplace feel safe, regulated, active, maintained, accessible, efficient, ordinary, and hard-working rather than dangerous, abandoned, dystopian, prison-like, or excessively automated. Use weathered umber brick, muted industrial green, galvanized steel, charcoal concrete, navy accents, restrained safety amber, warm cedar surfaces, rain-softened cool daylight, and warm practical fixtures. Preserve exactly the authored room-to-room routes and access level with all exits visibly separate and a generous uncluttered central and lower character-staging area. Workplace equipment must be parked or inactive, cargo stable, pedestrian lanes clear, and employee spaces dignified. No people or reflections of people, character sprites, navigation arrows, interface, readable safety signs, schedules, shift boards, manifests, package labels, names, addresses, company names, advertisements, words, letters, numbers, barcodes, logos, trademarks, brands, photo faces, active monitor content, weapons, drugs, blood, accidents, damaged parcels, falling cargo, spills, sparks, smoke, broken equipment, exposed hazards, prison imagery, dystopia, garbage, or watermark; all screens must be dark and all documents, labels, boxes, badges, panels, and papers must be blank, closed, face-down, abstract, turned away, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Security Desk | `greyport_distribution/security.png` | Three-way employee-and-interview entry with rear controlled Warehouse Floor gate, right Supervisor Office door, foreground Industrial Corner return, low security desk, dark monitors, visitor seating, and blank badge station. |
| Warehouse Floor | `greyport_distribution/warehouse_floor.png` | Employee-only three-way operations hub with left Loading Bays, right Break Room, foreground Security return, organized racking, blank sealed cargo, parked pallet equipment, and clear pedestrian lanes. |
| Loading Bays | `greyport_distribution/loading_bays.png` | Employee-only indoor dock with three closed roll-up doors, clean levelers and staging lanes, wrapped blank pallet, parked hand jack, fixed rainy panels, and one right Warehouse Floor return. |
| Break Room | `greyport_distribution/break_room.png` | Humane employee room with left Warehouse Floor return, sturdy tables, kitchenette, blank vending display, closed lockers, bench, fixed high rain window, and no other exit. |
| Supervisor Office | `greyport_distribution/supervisor_office.png` | Appointment-or-employee office with left Security return, dark monitor, interview chairs, closed files, blank planner grid, fixed rain window, and interior glazing that is not a passage. |

### Port Alder Transit Depot batch prompt set

This batch continues Greyport Industrial Corner into a maintained municipal transit
workplace supporting bus-pass service, transit employment, mechanics training, Daniel
Hale's established mechanic schedule, coworker stories, performance, and promotion. It
uses slate transit blue, cream, galvanized steel, charcoal concrete, deep navy, restrained
safety yellow, warm cedar and rubber, rain-softened coastal daylight, and practical warm
fixtures. The depot feels capable, humane, approachable, and workmanlike rather than
hazardous, grim, dystopian, prison-like, or like a corporate showroom.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside the Port Alder Transit Depot in polished painterly semi-realistic grounded cinematic realism. Continue Greyport Industrial Corner's rain-softened coastal industrial world and the depot's slate transit blue, cream, muted safety yellow, galvanized steel, charcoal concrete, deep navy, warm cedar, and rubber palette. Make the municipal transit workplace safe, well maintained, modest, functional, approachable, and dignified. Preserve exactly the authored room-to-room routes and access level with every exit visibly separate and a generous uncluttered lower area for floating navigation UI and character staging. Park buses safely with blank destination displays; keep tools stored, equipment stationary, floors clear, and employee areas humane. No people or reflections of people, character sprites, navigation arrows, interface, readable service signs, route maps, route numbers, schedules, training materials, labels, names, addresses, advertisements, words, letters, numbers, logos, trademarks, brands, photo faces, active screen content, readable paperwork, weapons, drugs, alcohol, blood, accidents, damaged buses, spills, sparks, smoke, broken equipment, exposed hazards, prison imagery, dystopia, garbage, luxury-showroom styling, or watermark; all screens must be dark and all papers, panels, displays, binders, bins, boxes, and boards must be blank, closed, turned away, abstract, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Public Counter | `port_alder_transit_depot/public_counter.png` | Three-way civic entry with a broad rear Repair Bays passage, right Foreman Office door, near-foreground public exit to Industrial Corner, service counter, modest waiting area, dark displays, and blank panels. |
| Repair Bays | `port_alder_transit_depot/repair_bays.png` | Employee-only three-way mechanics hub with left Parts Room, right Break Room, foreground Public Counter return, two safely parked unbranded buses, inactive lifts, stored tools, and clear floor lanes. |
| Parts Room | `port_alder_transit_depot/parts_room.png` | Organized employee storeroom with generic turned-away parts bins, maintained shelving, clean worktable, parked hand cart, dark terminal, and exactly one right Repair Bays return. |
| Break Room | `port_alder_transit_depot/break_room.png` | Dignified staff recovery space with durable tables, seating, kitchenette, closed cabinets, dark screen, blank pinboard, and exactly one left Repair Bays return. |
| Foreman Office | `port_alder_transit_depot/foreman_office.png` | Appointment-or-employee office for interviews, training, scheduling, performance, and promotion with visitor chairs, blank planner, closed files, dark monitor, and exactly one left Public Counter return. |

### Greyport Studios batch prompt set

This batch continues Greyport Apartment Block into a compact affordable studio-rental
building supporting viewings, lease requirements, the player's first independent home,
sleep, wardrobe, cooking, hygiene, laundry, mail, budgeting, relationships, and household
customization. The carefully maintained older building uses aged red brick, warm cream,
faded teal, honey oak, charcoal metal, restrained mustard, aged brass, rain-grey blue,
old terrazzo, repaired plaster, and warm practical fixtures. It feels modest, secure,
neighborly, and hopeful rather than luxurious, shabby, unsafe, institutional, or like a
poverty caricature.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside Greyport Studios in polished painterly semi-realistic grounded mature contemporary realism. Continue Greyport Apartment Block's rainy coastal brick architecture and use aged red brick, warm cream, faded teal, honey oak, charcoal metal, restrained mustard, aged brass, smoky rain-grey blue, repaired plaster, old terrazzo or wood floors, durable upholstery, and warm practical lights. Make the affordable studio building carefully maintained, compact, secure, neighborly, functional, dignified, and suitable for both rental viewing and long-term player residence. Preserve exactly the authored room-to-room routes and access level with every exit visibly separate and a generous uncluttered central and lower area for floating navigation UI and character staging. No people or reflections of people, character sprites, navigation arrows, interface, readable rent notices, bills, mail, addresses, tenant names, unit numbers, appliance labels, advertisements, words, letters, numbers, logos, trademarks, brands, photo faces, active screen content, readable paperwork, alcohol displays, drugs, weapons, intimate clutter, underwear, broken fixtures, exposed hazards, luxury styling, shabby decay, poverty caricature, institutional gloom, or watermark; all screens must be dark and all papers, boards, mailbox faces, parcel lockers, containers, and labels must be blank, closed, turned away, abstract, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Lobby | `greyport_studios/lobby.png` | Four-way rental and resident hub with left Laundry Room, central rear stairs to the Studio Unit, right Mail Room, foreground Apartment Block exit, modest seating, blank notice board, dark intercom, umbrella stand, and no other route. |
| Studio Unit | `greyport_studios/studio_unit.png` | Compact furnished adult living-and-sleeping room with double bed, sofa, desk, dresser, closed wardrobe, dining table, rainy brick view, right Kitchen doorway, foreground stair return to the Lobby, and no kitchenette or extra exit. |
| Private Kitchen | `greyport_studios/kitchen.png` | Practical older galley kitchen with left Studio Unit, right Bathroom, maintained cream cabinetry, honey-oak counters, safe compact appliances, fixed rainy window, and exactly those two routes. |
| Private Bathroom | `greyport_studios/bathroom.png` | Clean cream-and-faded-teal bathroom with tub-shower, toilet, vanity, closed storage, radiator, frosted rainy window, plain toiletries, and exactly one left Kitchen return. |
| Laundry Room | `greyport_studios/laundry.png` | Resident-and-guest shared laundry with abstract-panel machines, folding counter, utility sink, cart, closed storage, blank board, fixed high rain window, and exactly one right Lobby return. |
| Mail Room | `greyport_studios/mail_room.png` | Lease-only secure mail room with blank brass-and-charcoal mailboxes and parcel lockers, sorting shelf, bench, blank board, dark intercom, fixed rainy window, and exactly one left Lobby return. |

### Undertow Nightclub batch prompt set

This batch continues Greyport Nightlife Alley into an adults-only converted-warehouse
nightclub supporting dancing, live music, public dates, friendship events, alcohol and
alcohol-free service, hydration, intoxication-aware choices, sensory recovery, inclusive
facilities, floor-staff employment, and promotion. Undertow is deliberately rawer and more
affordable than Tideglass Club, using weathered umber brick, soot-black steel, charcoal
concrete, deep ocean indigo, electric cyan, restrained violet, rust orange, aged copper,
perforated acoustic metal, and warm practical fixtures. It remains maintained, mature,
inclusive, high-visibility, and safe rather than dangerous, exploitative, sexually themed,
abandoned, or dystopian.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside Undertow Nightclub in polished painterly semi-realistic grounded mature contemporary cinematic realism. Continue Greyport Nightlife Alley's rainy converted-warehouse architecture and use weathered umber brick, soot-black steel, charcoal sealed concrete, deep ocean indigo, electric cyan, restrained violet, rust orange, aged copper, perforated acoustic metal, durable dark upholstery, and warm practical fixtures. Make Undertow energetic, adults-only, inclusive, maintained, affordable, safe, consent-aware, intoxication-aware, and distinctly rawer than the upscale Tideglass Club. Preserve exactly the authored room-to-room routes and access level with every exit visibly separate, clear sightlines, accessible circulation, and a generous uncluttered central and lower area for floating navigation UI and character staging. No people, reflections, or silhouettes of people, character sprites, navigation arrows, interface, readable age notices, menus, prices, drink labels, schedules, tenant or employee names, club name, posters, advertisements, words, letters, numbers, logos, trademarks, brands, photo faces, active screen content, readable paperwork, drugs, weapons, blood, broken glass, spills, intoxicated mess, sexualized imagery, cages, poles, bondage imagery, threatening security, exposed hazards, smoke-obscured visibility, abandoned decay, luxury styling, or watermark; all screens must be dark and all bottles, papers, boards, panels, tickets, containers, and labels must be blank, closed, turned away, abstract, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Club Entrance | `undertow_nightclub/entry.png` | Three-way age-aware foyer with rear Coat Check, right Dance Floor, left rainy Nightlife Alley return, dark check-in podium, bench, bag shelf, water station, acoustic panels, and no extra route. |
| Coat Check | `undertow_nightclub/coat_check.png` | Organized public coat storage with sturdy counter, empty hangers, closed cubbies, umbrella rack, bench, dark terminal, and exactly one foreground Entrance return. |
| Dance Floor | `undertow_nightclub/dance_floor.png` | Four-way central hub with left Bar, guarded rear DJ Booth stair, right Lounge, foreground Entrance return, broad safe dancing area, mounted light rig, acoustic treatment, and free-water station. |
| Bar | `undertow_nightclub/bar.png` | Two-way social and employment space with rear employee Staff Room door, right Dance Floor opening, sturdy copper-and-dark-wood counter, blank generic bottles, water and alcohol-free setup, dark screens, and clear dialogue space. |
| DJ Booth | `undertow_nightclub/dj_booth.png` | Employee-or-appointment technical booth with professional stationary equipment, dark displays, organized cables, safe rail, empty Dance Floor view, and exactly one foreground guarded return. |
| Lounge | `undertow_nightclub/lounge.png` | Three-way quieter social hub with left Dance Floor, rear Restrooms, right Quiet Room, durable booths, clear tables, water station, acoustic panels, and public sightlines for dates and consent check-ins. |
| Restrooms | `undertow_nightclub/restrooms.png` | Clean inclusive shared sink area with fully enclosed private stalls, wider accessible stall, closed storage, mirrors showing no people or extra routes, and exactly one foreground Lounge return. |
| Quiet Room | `undertow_nightclub/quiet_room.png` | Public sensory-decompression room with upright seating, acoustic panels, clear table, water, dimmable lamps, dark call panel, fixed privacy glass, and exactly one left Lounge return; no private-intimacy cues. |
| Staff Room | `undertow_nightclub/staff_room.png` | Dignified employee room with table, kitchenette, closed lockers, bench, blank shift board, dark terminal, hydration supplies, closed safety storage, and exactly one foreground Bar return. |

### Cedar Vale Residential Street batch prompt set

This batch establishes Cedar Vale as Port Alder's practical, multigenerational family
district and makes its discoverable travel structure readable without a quick-travel
overlay. The five outdoor rooms form a continuous route from transit through townhouse
and detached housing to family services, care work, and recreation. Rachel's private
townhouse door remains visually separate from the generic property-viewing entrance so
invitations, quests, and housing discovery can unlock them independently.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination in Cedar Vale Residential Street in polished painterly semi-realistic grounded mature contemporary cinematic realism. Use bright overcast late-August daylight immediately after light rain, mature cedars and maples, gentle inland hills, accessible sidewalks and curb ramps, maintained native planting, cedar-red and sage siding, warm cream brick, muted burgundy, honey wood, charcoal slate, moss, rain-grey blue, and restrained golden amber. Make Cedar Vale welcoming, practical, family-oriented, multigenerational, and distinct from Alder Heights without looking luxurious, gated, neglected, or institutional. Preserve exactly the authored room-to-room routes with every destination visibly separate and a generous uncluttered central or lower space for character staging and floating navigation UI. No people, children, reflections, silhouettes, character sprites, navigation arrows, interface, readable words, letters, numbers, addresses, signs, advertisements, logos, brands, trademarks, active screens, paperwork, vehicles blocking routes, or watermark.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Cedar Vale Bus Stop | `cedar_vale_street/bus_stop.png` | Terminal district arrival with timber shelter, dark blank kiosk, wet turnaround, and exactly one rightward street-and-sidewalk continuation into Townhouse Row. |
| Townhouse Row | `cedar_vale_street/townhouse_row.png` | Four-way housing hub with left Bus Stop return, one rear invitation-gated townhouse door, right Family Block route, and a physically separate foreground generic townhouse-development entry for rental or purchase viewing. |
| Family Block | `cedar_vale_street/family_block.png` | Four-way community hub with left Townhouse Row, a residential-scale rear Care Home entrance, right Detached Home Lane, and a separate warmer foreground Family Centre entrance for childcare, parenting, support, and employment scenes. |
| Detached Home Lane | `cedar_vale_street/detached_home_lane.png` | Three-way residential junction with left Family Block return, one centered generic detached-home property entrance, and right Neighborhood Playground continuation; other homes remain non-navigable background texture. |
| Neighborhood Playground | `cedar_vale_street/playground.png` | Empty inclusive public playground with accessible equipment, benches, picnic table, safety surfacing, continuous planted enclosure, and exactly one left return to Detached Home Lane. |

### Rachel's Townhouse batch prompt set

This batch continues the specific invitation-gated door on Cedar Vale's Townhouse Row
into the attainable two-adult rental shared by Rachel Morgan and an unnamed trainer
roommate. The home is organized, energetic, warm, and practical without becoming a
private gym or luxury show home. Rachel's permission-gated bedroom reflects coaching,
running, career ambition, discipline, and recovery without exposing relationship,
reproductive, medical, or adult-preference data. The roommate's fully restricted room
remains dignified, identity-neutral, and deliberately route-free.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside Rachel Morgan's hidden invitation-only Cedar Vale rental townhouse in polished painterly semi-realistic grounded mature contemporary cinematic realism. Continue Cedar Vale Townhouse Row's rain-softened late-August architecture with warm cream, sage, smoked teal, muted terracotta, cedar red, honey oak, charcoal metal, moss, rain-grey blue, and restrained amber practical light. Make the shared two-adult home attainable, maintained, organized, active, comfortable, and welcoming rather than luxurious, clinical, student-dorm-like, family-with-children-coded, or a private gym. Preserve exactly the authored room-to-room routes and access level, with each exit visibly separate and generous uncluttered central or lower character-staging space. Rachel's relationship-permission bedroom may express fitness coaching, running, career ambition, discipline, and recovery through restrained equipment and dark or closed materials; the unnamed roommate's restricted room must remain dignified, identity-neutral, biography-free, and route-free. No people, reflections, silhouettes, character sprites, navigation arrows, interface, readable mail, books, schedules, workout or nutrition plans, certificates, race numbers, labels, names, addresses, signs, words, letters, numbers, logos, trademarks, brands, photo faces, active screens, pregnancy or fertility clues, medicine, sexual or fetish cues, nudity, underwear, alcohol, drugs, weapons, clutter piles, broken fixtures, or watermark; all screens must be dark and all papers, containers, and storage blank, closed, face-down, plain, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Front Door | `rachel_cedar_vale_townhouse/front_door.png` | Shallow shared-adult foyer with rain-visible exterior threshold returning to Townhouse Row, one right Living Room opening, compact shoe and coat storage, restrained active-lifestyle details, and exactly those two routes. |
| Living Room | `rachel_cedar_vale_townhouse/living_room.png` | Four-way social hub with left Front Door, upper stair to Rachel's permission-gated Bedroom, right Kitchen, glazed Patio door, terracotta seating, dark television, and restrained recovery storage. |
| Kitchen | `rachel_cedar_vale_townhouse/kitchen.png` | Practical honey-oak shared kitchen with left Living Room opening, lower foreground Bathroom threshold, simple meal-preparation space, two-adult breakfast seating, and exactly those two routes. |
| Rachel's Bedroom | `rachel_cedar_vale_townhouse/rachel_bedroom.png` | Relationship-permission adult bedroom with smoked-teal and terracotta bedding, running shoes, work bag, recovery basket, restrained training equipment, closed storage, and one foreground Living Room return. |
| Roommate Bedroom | `rachel_cedar_vale_townhouse/roommate_bedroom.png` | Fully restricted identity-neutral adult bedroom with plain sage and rain-grey bedding, ordinary furniture, dark screen, closed storage, fixed rainy window, no personal biography clues, and zero visible navigation routes. |
| Bathroom | `rachel_cedar_vale_townhouse/bathroom.png` | Compact cream-and-smoked-teal shared bathroom with tub-shower, ordinary paired storage, fixed frosted rain window, and exactly one rear Kitchen return. |
| Patio | `rachel_cedar_vale_townhouse/patio.png` | Small enclosed rain-softened patio with cedar privacy fencing, modest two-adult furniture, tended containers, recovery mat, and exactly one glazed Living Room return. |

### Cedar Vale Townhouses batch prompt set

This batch continues the generic property-viewing entrance from Cedar Vale's
Townhouse Row into a representative townhouse that the player can rent or purchase.
It is professionally staged, attainable, identity-neutral, and ready for later player
customization rather than pre-owned by a named character. Its light oak, warm ivory,
pale sage, coastal blue-grey, muted clay, and charcoal palette keeps it visually
distinct from Rachel's darker, more athletic shared home.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside a representative rentable-and-purchasable Cedar Vale townhouse in polished painterly semi-realistic grounded mature contemporary cinematic realism. Continue Cedar Vale's rain-softened late-August architecture with warm ivory, pale sage, coastal blue-grey, light oak, muted clay, charcoal metal, linen, rain-grey blue, and restrained amber practical light. Make the home professionally staged, attainable, maintained, neutral, move-in-ready, and suitable for a property viewing or future player residence rather than luxurious, character-owned, child-coded, student-dorm-like, or clinical. Preserve exactly the authored room-to-room routes, with every exit visibly separate and generous uncluttered central or lower character-staging space. No people, children, reflections, silhouettes, character sprites, navigation arrows, interface, readable words, letters, numbers, addresses, listings, prices, signs, labels, mail, paperwork, logos, trademarks, brands, photo faces, active screens, resident identity, medicine, sexual cues, alcohol, drugs, weapons, clutter piles, broken fixtures, or watermark; all screens and appliance panels must be dark and blank.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Townhouse Entry | `cedar_vale_townhouses/entry.png` | Neutral viewing threshold with a street-facing exterior return and one visibly separate right Living Room opening, compact blank storage, and exactly those two routes. |
| Living Room | `cedar_vale_townhouses/living_room.png` | Four-way player-home hub with left Entry return, upper stair to the Primary Bedroom, right Kitchen opening, rear glazed Yard door, flexible staged seating, and exactly those four routes. |
| Kitchen | `cedar_vale_townhouses/kitchen.png` | Practical light-oak kitchen with left Living Room, upper Second Bedroom route, right Laundry opening, lower Bathroom threshold, simple food-preparation space, and exactly those four routes. |
| Primary Bedroom | `cedar_vale_townhouses/primary_bedroom.png` | Neutral adult bedroom prepared for player, partner, wardrobe, and customization systems, with closed storage and exactly one lower Living Room return. |
| Second Bedroom | `cedar_vale_townhouses/second_bedroom.png` | Flexible adult guest, roommate, or study room without child or resident cues, with closed storage and exactly one lower Kitchen return. |
| Bathroom | `cedar_vale_townhouses/bathroom.png` | Clean warm-ivory and pale-sage bathroom with tub-shower, blank storage, fixed rain-softened window, and exactly one rear Kitchen return. |
| Laundry | `cedar_vale_townhouses/laundry.png` | Compact household service room with blank dark appliance panels, plain closed storage, uncluttered work surface, and exactly one left Kitchen return. |
| Small Yard | `cedar_vale_townhouses/yard.png` | Modest enclosed rain-softened yard with cedar privacy fencing, adaptable seating and planting space, no side gate, and exactly one glazed Living Room return. |

### Cedar Vale Detached Homes batch prompt set

This batch continues the property entrance on Cedar Vale's Detached Home Lane into a
representative three-bedroom house available to rent or purchase. It is a meaningful
housing upgrade from the townhouse without becoming a mansion: the larger plan adds a
dining room, future-child bedroom, garage, and expanded yard while remaining attainable,
professionally staged, identity-neutral, and ready for long-term player customization.
Warm cream, caramel oak, moss green, slate blue, muted rust, river stone, and dark bronze
connect the interior to the cedar-and-stone exterior and distinguish it from both generic
townhouse and Rachel's home.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside or immediately behind a representative rentable-and-purchasable three-bedroom Cedar Vale detached house in polished painterly semi-realistic grounded mature contemporary cinematic realism. Continue the cedar-and-stone house shown on rain-softened Detached Home Lane with warm cream, caramel oak, moss green, slate blue, muted rust, river stone, dark bronze, and rain-grey blue. Make the house larger and better equipped than the townhouse while remaining attainable, professionally staged, maintained, family-ready, identity-neutral, move-in-ready, and suitable for a property viewing or future player residence rather than luxurious, mansion-like, character-owned, child-cluttered, student-like, or clinical. Preserve exactly the authored room-to-room routes, with every exit visibly separate and generous uncluttered central or lower character-staging space. No people, children, animals, reflections of figures, silhouettes, character sprites, navigation arrows, interface, readable words, letters, numbers, addresses, listings, prices, signs, labels, mail, paperwork, logos, trademarks, brands, photo faces, active screens, resident identity, medicine, alcohol, drugs, weapons, sexual cues, underwear, clutter piles, broken fixtures, extra routes, or watermark; all screens, appliance panels, containers, and storage must be dark, blank, plain, or closed.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Home Foyer | `cedar_vale_detached_homes/foyer.png` | Spacious viewing threshold with a wet front-walk return to Detached Home Lane, one separate right Living Room opening, practical closed storage, and exactly those two routes. |
| Living Room | `cedar_vale_detached_homes/living_room.png` | Four-way social and family hub with left Foyer, upper stair to the Primary Bedroom, right Dining Room, centered glazed Yard doors, modest river-stone fireplace, and exactly those routes. |
| Kitchen | `cedar_vale_detached_homes/kitchen.png` | Better-equipped but attainable moss-grey and warm-ivory kitchen viewed from the lower Dining Room return, with one separate right Laundry doorway and exactly those two routes. |
| Dining Room | `cedar_vale_detached_homes/dining_room.png` | Three-way meal, conversation, date, and family room with separate left Living Room, rear Kitchen, and right Second Bedroom openings around an unobstructed six-seat table. |
| Primary Bedroom | `cedar_vale_detached_homes/primary_bedroom.png` | Neutral adult room with closed storage, a lower Living Room or stair-landing return, separate right Child Bedroom doorway, and no ensuite or balcony shortcut. |
| Child Bedroom | `cedar_vale_detached_homes/child_bedroom.png` | Safe age-flexible future-player-child room with a single bed, blank desk, closed toy storage, nonbranded wooden toys, no preassigned identity, and one left Primary Bedroom return. |
| Second Bedroom | `cedar_vale_detached_homes/second_bedroom.png` | Flexible adult guest, roommate, relative, or study room with a left Dining Room doorway, lower tiled Bathroom threshold, closed storage, and exactly those two routes. |
| Bathroom | `cedar_vale_detached_homes/bathroom.png` | Full warm-ivory and river-stone household bathroom with tub-shower, closed vanity, fixed frosted window, and one rear Second Bedroom return. |
| Laundry | `cedar_vale_detached_homes/laundry.png` | Organized two-route service room with left Kitchen, right Garage, blank dark appliance panels, closed moss-grey storage, and clear circulation. |
| Garage | `cedar_vale_detached_homes/garage.png` | Secure empty parking bay prepared for later player-owned vehicle representation, fully closed overhead door, blank storage, and one left Laundry return without an exterior shortcut. |
| Yard | `cedar_vale_detached_homes/yard.png` | Larger enclosed lawn and wet-stone patio with continuous cedar fencing, adaptable planting and seating space, and one centered glazed Living Room return. |

### Cedar Vale Care Home batch prompt set

This batch continues Cedar Vale Family Block's residential-scale care entrance into a
dignified five-room facility supporting employment, family visits, resident social life,
shared meals, and accessible outdoor activity. The design uses supportive seating, wide
clear circulation, level thresholds, and secure employee space without treating mobility
or aging as hospital scenery. Warm butter cream, natural oak, muted teal, sage, dusty
rose, soft burgundy, river stone, and restrained amber light keep the setting home-like,
multigenerational, and distinct from both a clinic and a hotel.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside or immediately behind Cedar Vale Care Home in polished painterly semi-realistic grounded mature contemporary cinematic realism. Continue the residential cedar, warm-cream brick, and river-stone building on rain-softened Family Block with warm butter cream, natural oak, muted teal, sage green, dusty rose, soft burgundy, river stone, dark bronze, rain-grey blue, and restrained amber practical light. Make the care home accessible, residential, maintained, comfortable, respectful, multigenerational, and dignified rather than clinical, institutional, hospital-like, luxurious, hotel-like, childish, or gloomy. Express accessibility through wide clear circulation, level thresholds, supportive seating, fixed handrails where useful, and uncluttered staging space rather than parked mobility equipment. Preserve exactly the authored room-to-room routes, with every exit visibly separate. No people, residents, staff, parked wheelchairs, reflections of figures, silhouettes, character sprites, navigation arrows, interface, readable words, letters, numbers, room names, signs, labels, schedules, resident records, mail, paperwork, logos, trademarks, brands, photo faces, active screens, visible medication, medical charts or devices, alcohol, drugs, weapons, sexual cues, clutter piles, broken fixtures, extra routes, or watermark; all screens, panels, containers, documents, books, and storage must be dark, blank, plain, closed, face-down, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Reception | `cedar_vale_care_home/reception.png` | Accessible three-way visitor threshold with front doors returning to Family Block, a discreet rear employee-only Care Station door, broad right Resident Lounge opening, curved oak desk, blank dark monitor, and exactly those routes. |
| Resident Lounge | `cedar_vale_care_home/resident_lounge.png` | Home-like social hub with left Reception, rear Dining Room, centered glazed Garden doors, supportive teal, sage, rose, and burgundy seating, modest river-stone fireplace, and exactly those three routes. |
| Dining Room | `cedar_vale_care_home/dining_room.png` | Residential shared dining room with several accessible four-seat tables, wide circulation, fixed rain-softened windows, closed sideboard and serving counter, and one lower Resident Lounge return. |
| Care Station | `cedar_vale_care_home/care_station.png` | Secure employee-only support office with two blank dark monitors, closed oak and sage storage, fixed rainy window, no exposed records or medicine, and one full-height walkable doorway returning to Reception. |
| Garden | `cedar_vale_care_home/garden.png` | Fully enclosed accessible courtyard with level wet paving, raised planters, supportive benches, internal returning garden loop, covered seating, continuous boundaries, and one centered glazed Resident Lounge return. |

### Cedar Vale Family Centre batch prompt set

This batch continues the warmer public entrance on Cedar Vale Family Block into a
five-room community support centre for childcare, parenting workshops, counseling,
and inclusive outdoor play. The centre is friendlier and more energetic than the Care
Home without becoming overstimulating or childish. Light birch, warm cream, pale aqua,
sage, soft coral, sunshine ochre, muted navy, river stone, and rain-grey blue unify the
rooms while appointment-controlled spaces remain private and free of client records.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside or immediately behind Cedar Vale Family Centre in polished painterly semi-realistic grounded mature contemporary cinematic realism. Continue the residential cedar, warm-cream brick, and river-stone Family Block building after light late-August rain with warm cream, light birch, pale aqua, sage green, soft coral, sunshine ochre, muted navy, river stone, rain-grey blue, and restrained amber practical light. Make the centre accessible, family-friendly, maintained, attainable, inclusive, welcoming, privacy-conscious, and dignified rather than clinical, institutional, luxurious, classroom-like, commercial-daycare-branded, cartoon-heavy, overstimulating, or gloomy. Preserve exactly the authored room-to-room routes, appointment boundaries, and fully enclosed playground, with every exit visibly separate and generous clear circulation. No people, children, parents, staff, parked strollers, reflections of figures, silhouettes, character sprites, navigation arrows, interface, readable words, letters, numbers, room names, signs, labels, schedules, worksheets, schoolwork, client records, mail, paperwork, logos, trademarks, brands, photo faces, active screens, medication, medical devices, alcohol, drugs, weapons, sexual cues, alphabet blocks or panels, realistic dolls, clutter piles, broken fixtures, extra routes, or watermark; all screens, panels, containers, documents, books, art paper, and storage must be dark, blank, plain, closed, face-down, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Reception | `cedar_vale_family_centre/reception.png` | Three-way accessible public threshold with front doors returning to Family Block, discreet rear appointment-controlled Childcare door, broad right Parent Group Room opening, curved birch desk, blank dark monitor, and child-safe waiting table. |
| Childcare Room | `cedar_vale_family_centre/childcare_room.png` | Empty supervised activity room with rounded tables, age-flexible text-free wooden toys, blank art paper, plain closed storage replacing the generated book rack, fixed rainy windows, and one lower Reception return. |
| Parent Group Room | `cedar_vale_family_centre/parent_group_room.png` | Public workshop and support hub with left Reception, rear private Counselor Office door, right glazed Playground doors, ten flexible adult chairs, dark blank display, closed storage, and exactly those three routes. |
| Family Counselor Office | `cedar_vale_family_centre/counselor_office.png` | Calm private appointment room with inclusive family seating, closed lockable storage, fixed rainy window, no desk barrier or records, and one lower Parent Group Room return. |
| Family Centre Playground | `cedar_vale_family_centre/playground.png` | Fully enclosed wet-weather accessible play space with ramped structure, basket swing, text-free sensory panels, broad turning space, supportive adult seating, continuous boundaries, and one left glazed Parent Group Room return. |

### Mariner Row Shopping Street batch prompt set

This batch establishes Mariner Row as a discoverable, walkable coastal retail spine in
converted warehouse storefronts. Store identities are communicated through architecture,
materials, and window displays instead of text signage, so every destination remains
legible while preserving the game's text-free background policy. Pale sandstone, warm
brick, weathered cedar, deep navy, seafoam green, rust orange, dark metal, restrained
brass, rain-grey blue, and wet-pavement reflections unify the four connected outdoor
rooms without making the district feel luxurious, tourist-oriented, or mall-like.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination on Mariner Row Shopping Street in polished painterly semi-realistic grounded mature contemporary cinematic realism. Establish a maintained, attainable, pedestrian coastal retail district adapted from warm-brick, pale-sandstone, weathered-cedar, and dark-metal warehouse storefronts in bright overcast late-August daylight immediately after light rain. Use deep navy, seafoam green, rust orange, restrained brass, rain-grey blue, native planters, simple benches, and soft reflections on wet paving. Identify stores only through visibly distinct architecture and neutral window displays; preserve exactly the authored street and storefront routes with every entrance and continuation physically separate. No people, animals, moving or parked street vehicles, reflections of figures, character sprites, navigation arrows, interface, readable words, letters, numbers, store names, route names, schedules, signs, labels, prices, advertisements, brands, logos, packaging, license plates, active screens, extra routes, alleys, stairs, side passages, cross streets, open gates, ambiguous gaps, tourist kitsch, dereliction, or watermark.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Mariner Row Transit Stop | `mariner_row_shopping_street/transit_stop.png` | Accessible western arrival with timber-and-glass shelter, blank route panel, bench with armrests, curb ramp, tactile paving, wet bus bay, harbor glimpse, one right Market Block route, and no other exit. |
| Market Block | `mariner_row_shopping_street/market_block.png` | Three-way grocery hub with left Transit Stop continuation, centered Mariner Market entrance identified by plain produce displays, right Fashion Block continuation, and all neighboring doors closed. |
| Fashion Block | `mariner_row_shopping_street/fashion_block.png` | Four-way pedestrian plaza with left Market Block and right Home and Auto Block continuations, a rear Northline Outfitters entrance identified by neutral outerwear, and a fully separate foreground Harbor Formalwear entrance in dark wood and brass. |
| Home and Auto Block | `mariner_row_shopping_street/home_and_auto_block.png` | Three-way endpoint with left Fashion Block continuation, centered Mariner Home Goods entrance identified by practical furniture displays, and a separate right Port Alder Auto showroom containing only modest unbranded display cars behind glass. |

### Mariner Market batch prompt set

This batch carries Mariner Row's converted-warehouse language into an attainable
five-room neighborhood grocery supporting everyday shopping, basic prepared food,
age-controlled beverage purchases, checkout scenes, and part-time employment. Warm
brick, weathered cedar, pale sandstone, deep navy, seafoam, rust orange, warm oak,
dark metal, polished grey flooring, and restrained amber light keep the interior tied
to the shopping street. Generic, blank product packaging preserves the text-free art
policy while produce, food, checkout equipment, bottles, and storage distinguish each
room by function.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside Mariner Market in polished painterly semi-realistic grounded mature contemporary cinematic realism. Continue Mariner Row's converted coastal warehouse architecture with warm brick, weathered cedar, pale sandstone, deep navy metal, seafoam green, rust orange, warm oak, matte grey flooring, and restrained amber practical light. Make the independent neighborhood grocery maintained, attainable, clean, organized, and useful for both shopping and employment rather than luxurious, enormous, branded, or mall-like. Preserve exactly the authored public, age-controlled, and employee-only routes with every doorway visibly separate. Keep the lower center clear enough for dialogue UI. No people, staff, customers, figures, silhouettes, reflections of figures, navigation arrows, interface, readable words, letters, numbers, store names, aisle markers, prices, menus, schedules, receipts, shipping labels, advertisements, trademarks, brands, logos, package labels, active screens, money left out, tobacco, weapons, clutter piles, extra routes, stairs, dereliction, or watermark; all products, containers, cartons, papers, panels, and screens must be blank, generic, turned away, closed, dark, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Grocery Floor | `mariner_market/grocery_floor.png` | Four-way public hub with left Checkout, rear Prepared Food, right age-controlled Alcohol Section, foreground glazed Market Block return, produce islands, basic aisles, and exactly those routes. |
| Prepared Food Counter | `mariner_market/prepared_food.png` | Compact counter alcove with plain sandwiches, salads, fruit, soup, and baked items in a clean refrigerated display, a closed preparation workspace, and one foreground Grocery Floor return. |
| Alcohol Section | `mariner_market/alcohol_section.png` | Restrained retail room with unopened generic bottles on dark-walnut shelving, no tasting or drinking area, continuous rear and right boundaries, and one broad left Grocery Floor return. |
| Checkout | `mariner_market/checkout.png` | Three modest staffed checkout counters with blank screens and payment terminals, a rear employee Stockroom doorway, broad right Grocery Floor opening, and no street exit. |
| Stockroom | `mariner_market/stockroom.png` | Orderly employee-only storage with navy shelving, plain cartons, closed supply cabinet, safe step stool, parked manual pallet jack, one Checkout return, and no loading-dock shortcut. |

### Northline Outfitters batch prompt set

This batch extends Mariner Row's converted-warehouse retail language into a practical
six-room clothing store supporting the full wardrobe system, weather-appropriate
clothing, fitting-room privacy, checkout, advice, and part-time employment. Warm brick,
weathered cedar, deep navy, seafoam, rust orange, pale sandstone, warm oak, dark metal,
matte grey flooring, and restrained amber track lighting maintain continuity with the
Fashion Block entrance. Everyday garment displays remain inclusive, attainable,
logo-free, mannequin-free, and non-sexual.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside Northline Outfitters in polished painterly semi-realistic grounded mature contemporary cinematic realism. Continue Mariner Row's converted coastal warehouse architecture with warm brick, weathered cedar, deep navy metal, seafoam green, rust orange, pale sandstone, warm oak, matte grey flooring, and restrained amber practical lighting. Make the clothing store organized, inclusive, attainable, privacy-conscious, and useful for wardrobe, weather, shopping, advice, and employment gameplay rather than luxurious, branded, sexualized, or mall-like. Preserve exactly the authored public and employee-only routes with every opening physically separate, and keep the lower center usable for dialogue UI. No people, staff, customers, figures, silhouettes, reflections of figures, mannequins, torsos, body forms, advertising photographs, faces, navigation arrows, interface, readable words, letters, numbers, store names, prices, sales signs, size markers, tags, receipts, shipping labels, trademarks, brands, logos, active screens, money left out, weapons, clutter piles, extra routes, stairs, dereliction, or watermark; all garments, boxes, garment covers, packages, papers, panels, and screens must be blank, generic, closed, dark, turned away, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Sales Floor | `northline_outfitters/sales_floor.png` | Four-way public hub with left Underwear, rear Fitting Rooms, right Outerwear, foreground Fashion Block return, everyday clothing tables, and exactly those routes. |
| Underwear Section | `northline_outfitters/underwear_section.png` | Respectful non-sexual displays of practical bras, briefs, boxer briefs, panties, undershirts, camisoles, socks, and sleepwear on hangers, shelves, and plain packages, with one right Sales Floor return. |
| Outerwear Section | `northline_outfitters/outerwear_section.png` | Weather-focused room with rain jackets, insulated coats, boots, gloves, scarves, and hats, plus separate left Sales Floor and right Checkout openings. |
| Fitting Rooms | `northline_outfitters/fitting_rooms.png` | Quiet gender-neutral fitting alcove with four closed private booths, accessible-width room, bench, empty mirror, closed return rail, and one Sales Floor return. |
| Checkout | `northline_outfitters/checkout.png` | Long navy-and-oak counter with two blank registers and terminals, broad left Outerwear opening, separate rear employee Stockroom doorway, and no street shortcut. |
| Stockroom | `northline_outfitters/stockroom.png` | Orderly employee-only storage with navy shelving and garment rails, folded reserve clothing, covered coats, plain shoe boxes, nested baskets, safe step ladder, packing table, one Checkout return, and no loading access. |

### Harbor Formalwear batch prompt set

This batch distinguishes Harbor Formalwear from Northline's practical outdoor store
through a warmer, quieter three-room interior for interview clothing, formal occasions,
private fitting, and professional alterations. Dark walnut, warm brick, cream curtains,
pale sandstone, deep navy, charcoal, pearl grey, muted wine, warm oak, restrained brass,
and soft amber lighting create refined presentation without making the shop inaccessible
or excessively luxurious. Clothing remains inclusive, modest, logo-free, mannequin-free,
and non-sexual.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside Harbor Formalwear in polished painterly semi-realistic grounded mature contemporary cinematic realism. Continue Mariner Row's converted coastal warehouse architecture while distinguishing the store through dark walnut, warm brick, cream, pale sandstone, deep navy, charcoal, pearl grey, muted wine, warm oak, restrained brass, and soft amber gallery lighting. Make the formalwear shop refined but attainable, inclusive, private, professional, and useful for interview clothing, suits, dresses, special occasions, fitting, and alterations rather than luxurious, bridal-only, sexualized, branded, or theatrical. Preserve exactly the authored routes with every opening physically separate and keep the lower center useful for dialogue UI. No people, staff, customers, figures, silhouettes, reflections of figures, mannequins, torsos, body forms, advertising photographs, faces, navigation arrows, interface, readable words, letters, numbers, store names, prices, measurements, tags, tickets, labels, brands, logos, active screens, money left out, clutter piles, exposed fitting activity, extra routes, stairs, dereliction, or watermark; all garments, garment covers, boxes, papers, swatches, panels, and screens must be blank, generic, closed, dark, face-down, turned away, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Showroom | `harbor_formalwear/showroom.png` | Three-way public hub with rear glazed Fashion Block entrance, separate right Fitting Room vestibule, foreground Tailoring Desk opening, dark-walnut formalwear displays, and exactly those routes. |
| Fitting Room | `harbor_formalwear/fitting_room.png` | Spacious private fitting salon with supportive wine bench, two empty mirrors, closed garment rail, accessible turning area, modest suit and dress, and one left Showroom return. |
| Tailoring Desk | `harbor_formalwear/tailoring_desk.png` | Orderly alterations workspace with walnut service desk, idle sewing machine, folded fabrics, blank swatches, safely stored tools, covered garments, closed storage, and one rear Showroom return. |

### Mariner Home Goods batch prompt set

This batch extends Mariner Row's converted-warehouse retail language into a practical
four-room household store supporting furniture purchases, home customization, décor,
kitchenware, basic appliances, and delivery arrangements. Warm brick, pale sandstone,
weathered oak, cream linen, muted sage, deep navy, terracotta, dark metal, restrained
brass, warm wood flooring, and practical lighting make the store inviting and attainable
rather than luxurious or warehouse-scaled.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside Mariner Home Goods in polished painterly semi-realistic grounded mature contemporary cinematic realism. Continue Mariner Row's converted coastal warehouse architecture with warm brick, pale sandstone, weathered oak, cream linen, muted sage, deep navy, terracotta, dark metal, restrained brass, warm wood or matte grey flooring, bright overcast window light, and warm practical lamps. Make the independent household store maintained, accessible, organized, attainable, and useful for furnishing, equipping, and customizing player residences rather than luxurious, branded, department-store-like, or a giant warehouse. Preserve exactly the authored routes with every opening physically separate and keep the lower center useful for dialogue UI. No people, staff, customers, figures, silhouettes, reflections of figures, photographic faces, navigation arrows, interface, readable words, letters, numbers, store names, prices, measurements, tags, delivery forms, labels, brands, logos, active screens, money left out, lit candles, weapons, clutter piles, extra routes, stairs, dereliction, or watermark; all products, packages, papers, art, panels, and screens must be blank, generic, abstract, closed, dark, face-down, turned away, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Furniture Floor | `mariner_home_goods/furniture_floor.png` | Three-way public hub with rear Décor, right Kitchen, foreground Home and Auto Block return, attainable living, dining, office and storage displays, broad circulation, and exactly those routes. |
| Kitchen Section | `mariner_home_goods/kitchen_section.png` | Organized cookware, tableware, storage and unplugged small-appliance displays with separate left Furniture Floor and right Checkout openings. |
| Décor Section | `mariner_home_goods/decor_section.png` | Practical cushions, throws, rugs, lamps, vases, planters, mirrors, baskets and abstract art with one clear Furniture Floor return. |
| Checkout | `mariner_home_goods/checkout.png` | Navy-and-oak service counter with blank register and terminal, plain wrapping and delivery supplies, one left Kitchen Section return, and no public or loading shortcut. |

### Port Alder Auto batch prompt set

This batch carries Mariner Row's converted-warehouse retail language into an
independent, attainable vehicle dealership supporting vehicle purchases, financing,
used-car browsing, and maintenance arrangements. Warm brick, pale sandstone, deep
navy metal, weathered oak, charcoal concrete, broad glass, cool coastal daylight,
rain-softened exteriors, and warm practical lamps distinguish it from the neighboring
home store while preserving the shared Home and Auto Block architecture.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside Port Alder Auto in polished painterly semi-realistic grounded mature contemporary cinematic realism. Continue Mariner Row's converted coastal warehouse architecture with warm brick, pale sandstone, deep navy metal framing, weathered oak, polished charcoal concrete, broad glass, cool rainy overcast daylight, and warm practical lighting. Make the independent dealership maintained, professional, approachable, and attainable rather than luxurious, branded, corporate, or oversized. Use clean generic compact cars, sedans, hatchbacks, and family vehicles without identifying marks. Preserve exactly the authored routes with every opening physically separate and keep the lower center useful for dialogue UI. No people, staff, customers, mechanics, figures, silhouettes, reflections of figures, photographic faces, navigation arrows, interface, readable words, letters, numbers, dealership names, prices, rates, contracts, service menus, tags, brands, logos, emblems, model badges, license plate text, active screens, money, keys left out, weapons, hazardous spills, clutter, extra routes, stairs, dereliction, fisheye distortion, or watermark; all papers, tags, stickers, plates, screens, cabinets, wall panels, forms, and signs must be blank, dark, abstract, closed, face-down, turned away, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Showroom | `port_alder_auto/showroom.png` | Four-way public hub with far-left Home and Auto Block exit, rear Finance Office, far-right Used Car Lot doors, foreground Service Desk connection, practical generic display vehicles, and exactly those routes. |
| Used Car Lot | `port_alder_auto/used_lot.png` | Secure rain-wet exterior lot with orderly attainable used vehicles, an enclosed perimeter, canopy lighting, and one clear left return through the Showroom doors. |
| Finance Office | `port_alder_auto/finance_office.png` | Private brick-and-glass customer office with oak desk, three chairs, blank dark monitor, closed files, face-down paperwork, and one clear downward return to the Showroom. |
| Service Desk | `port_alder_auto/service_desk.png` | Navy-and-oak service reception with blank dark terminals, waiting chairs, sealed workshop observation glass, and one clear upward return to the Showroom. |

### St. Maren Medical Center batch prompt set

This batch establishes the medical district's central 13-room hospital campus from
transit arrival and outpatient walks through emergency care, inpatient family health,
diagnostics, staff work, and the cafeteria. Pale limestone, soft blue-grey glazing,
weathered cedar, sea-green privacy glass, warm white walls, navy service counters,
charcoal resilient flooring, coastal planting, and warm practical lighting create a
calm, accessible, inclusive institution. Every clinical room remains non-graphic,
private, maintained, and appropriate for a mature dramatic visual novel.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination at St. Maren Medical Center in polished painterly semi-realistic grounded mature contemporary cinematic realism. Use pale limestone, soft blue-grey glass, weathered cedar, sea-green privacy glazing and upholstery, warm off-white walls, navy-and-oak service counters, charcoal and light-grey resilient flooring, warm practical lamps, cool coastal daylight, rain-darkened exterior paving, and restrained native planting. Make the public hospital modern, maintained, human-scaled, accessible, inclusive, private, clinically believable, and reassuring rather than luxurious, futuristic, institutional, frightening, or crowded. Preserve exactly the authored routes, distinguish public and staff-only connections, keep every path level and accessible, and leave the lower center useful for dialogue UI. No people, staff, patients, visitors, children, infants, figures, silhouettes, reflections of figures, photographic faces, navigation arrows, interface, readable words, letters, numbers, hospital or department names, directories, room numbers, patient names, charts, forms, labels, schedules, menus, maps, signs, logos, brands, active screens, blood, injuries, birth in progress, anatomy, bodily fluids, needles, sharps, exposed medication, biohazard symbols, weapons, panic, clutter, extra routes, stairs, dereliction, fisheye distortion, or watermark; all equipment, paperwork, clocks, panels, screens, cabinets, menus, maps, signs, and labels must be blank, dark, closed, face-down, abstract, generic, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| St. Maren Transit Stop | `st_maren_medical_center/campus_transit_stop.png` | Accessible glass-and-cedar bus shelter, wet roadway, native planting, blank route panel, and one covered rightward path to the Campus Plaza. |
| Medical Campus Plaza | `st_maren_medical_center/campus_plaza.png` | Four-way exterior hub with left Transit path, central Reception doors, right Clinic Walk, and a distinct level covered Emergency approach. |
| Clinic Walk | `st_maren_medical_center/clinic_walk.png` | Accessible outpatient promenade connecting left Campus Plaza, rear Community Clinic, right Wellness Walk, and separate foreground Family Doctors entrance. |
| Wellness Walk | `st_maren_medical_center/wellness_walk.png` | Quiet landscaped court connecting left Clinic Walk, rear Therapy, right Pharmacy, and a discreet separately screened Sexual Health entrance. |
| Emergency Department | `st_maren_medical_center/emergency.png` | Calm triage reception and waiting area with rear Plaza doors, right Main Reception corridor, blank terminals, and no emergency in progress. |
| Main Reception | `st_maren_medical_center/reception.png` | Four-way hospital lobby with left Emergency, rear Inpatient lift, right Cafeteria, foreground Plaza doors, and blank information counter. |
| Inpatient Ward | `st_maren_medical_center/inpatient_ward.png` | Upper-floor hub with left Maternity corridor, right Pediatrics corridor, central Reception lift, family seating, and closed subordinate patient rooms. |
| Maternity Ward | `st_maren_medical_center/maternity.png` | Private non-graphic maternity room with one prepared bed, empty bassinet, support seating, inactive blank monitors, and one right Ward return. |
| Pediatrics | `st_maren_medical_center/pediatrics.png` | Reassuring family assessment room with clean bed, caregiver seating, simple generic toys, blank monitor, and one left Ward return. |
| Laboratory | `st_maren_medical_center/laboratory.png` | Hygienic clinical collection room with empty chairs, closed supplies, idle generic analyzers, right Imaging route, and foreground Cafeteria return. |
| Imaging | `st_maren_medical_center/imaging.png` | Quiet diagnostic suite with generic CT-style scanner, sealed control window, left Laboratory return, and separate rear Staff Station route. |
| Nursing Station | `st_maren_medical_center/staff_station.png` | Secure employee work hub with navy-and-oak desk, blank monitors, closed records and supplies, sealed window, and one Imaging return. |
| Cafeteria | `st_maren_medical_center/cafeteria.png` | Accessible public dining room with generic prepared foods, blank menu panels, left Reception corridor, and separate Laboratory lift. |

### St. Maren Community Clinic batch prompt set

This five-room batch extends the medical center's calm palette into a smaller weekday
outpatient clinic supporting Elena's work, general checkups, illness care, referrals,
records administration, and private workplace conversations. It retains St. Maren's
pale limestone, sea-green privacy glass, warm off-white walls, weathered cedar, navy
service counters, charcoal resilient flooring, coastal art, and soft practical light
while feeling more personal and less institutional than the hospital.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside St. Maren Community Clinic in polished painterly semi-realistic grounded mature contemporary cinematic realism. Match the medical campus through warm off-white walls, pale limestone trim, sea-green privacy glass and upholstery, weathered cedar furniture and handrails, navy-and-oak service surfaces, charcoal and light-grey resilient flooring or carpet tile, abstract coastal art without faces, indoor plants, cool coastal daylight, and warm practical lamps. Make the weekday outpatient clinic maintained, human-scaled, accessible, inclusive, private, clinically believable, and reassuring rather than luxurious, futuristic, crowded, or hospital-sized. Preserve exactly the authored routes, clearly distinguish public, appointment, and employee spaces, and keep the lower center useful for dialogue UI. No people, staff, patients, figures, silhouettes, reflections of figures, photographic faces, navigation arrows, interface, readable words, letters, numbers, clinic names, patient names, notices, schedules, charts, forms, prescriptions, folder labels, calendars, signs, logos, brands, active screens, blood, injuries, anatomy posters, bodily fluids, needles, exposed medicine, loose keys, weapons, clutter, extra routes, stairs, dereliction, fisheye distortion, or watermark; all screens, papers, planners, files, folders, cabinets, equipment, clocks, panels, signs, and labels must be blank, dark, closed, capped, face-down, locked, abstract, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Reception | `st_maren_community_clinic/reception.png` | Three-way public hub with rear Records Office door, right Waiting Room, foreground Clinic Walk doors, navy counter, and blank terminals. |
| Waiting Room | `st_maren_community_clinic/waiting_room.png` | Accessible sea-green seating room with left Reception, rear Administrator Office, right Exam Room, water station, and blank screen. |
| Exam Room | `st_maren_community_clinic/exam_room.png` | Private general-practice room with exam table, visitor seating, blank monitor, closed clinical storage, and one left Waiting Room return. |
| Records Office | `st_maren_community_clinic/records_office.png` | Secure employee workspace with locked closed record cabinets, blank scanning station, face-down folders, and one Reception return. |
| Administrator Office | `st_maren_community_clinic/administrator_office.png` | Elena's private cedar office with conversational seating, blank monitor, closed planner and files, campus window, and one Waiting Room return. |

### St. Maren Family Doctors batch prompt set

This four-room batch continues the medical campus palette in a compact primary-care
practice for appointments, walk-ins, medication discussions, health-record reviews,
and fertility referrals. The reception and waiting room preserve the authored Clinic
Walk connection, while the two private rooms remain visually distinct: Exam Room 1 is
equipped for routine physical assessment and Exam Room 2 emphasizes seated consultation.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside St. Maren Family Doctors in polished painterly semi-realistic grounded mature contemporary cinematic realism. Match the St. Maren medical campus through warm off-white walls, pale limestone trim, muted sea-green and blue-grey upholstery, weathered cedar furniture and handrails, navy-and-oak service surfaces, charcoal and light-grey resilient flooring or carpet tile, abstract coastal art without faces, indoor plants, cool coastal daylight, and warm practical lamps. Make the weekday family practice compact, maintained, accessible, inclusive, clinically believable, private, and reassuring rather than luxurious, futuristic, crowded, or hospital-sized. Preserve exactly the authored routes, clearly distinguish public waiting from private appointment spaces, and keep the lower center useful for dialogue UI. No people, staff, patients, figures, silhouettes, reflections of figures, photographic faces, navigation arrows, interface, readable words, letters, numbers, clinic names, patient names, notices, schedules, charts, forms, prescriptions, folder labels, calendars, signs, logos, brands, active screens, blood, injuries, anatomy posters, bodily fluids, needles, exposed medicine, loose keys, weapons, clutter, extra routes, stairs, dereliction, fisheye distortion, or watermark; all screens, papers, files, folders, cabinets, equipment, clocks, panels, signs, and labels must be blank, dark, closed, capped, face-down, locked, abstract, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Reception | `st_maren_doctors_office/reception.png` | Compact blue-grey-and-oak arrival desk with left Clinic Walk exit, right Waiting Room route, blank terminals, private counter geometry, and clear central staging. |
| Waiting Room | `st_maren_doctors_office/waiting_room.png` | Calm public seating room with left Reception return, rear Exam Room 1, right Exam Room 2, muted upholstery, a water station, and blank display. |
| Exam Room 1 | `st_maren_doctors_office/exam_room_1.png` | General physical-assessment room with exam bed, clinician stool, visitor chair, sink, closed supplies, blank monitor, and one centered Waiting Room return. |
| Exam Room 2 | `st_maren_doctors_office/exam_room_2.png` | Consultation-focused room with round table, three chairs, compact exam bed, closed storage, blank records screen, and one left Waiting Room return. |

### Harbor Wellness Therapy batch prompt set

This five-room batch creates a confidential counseling practice that feels warmer and
more residential than the neighboring medical clinics. Reception preserves the Wellness
Walk connection, the Waiting Lounge presents all four interior routes, and the three
appointment rooms use distinct layouts for individual, relationship, and group sessions.
All rooms use level accessible thresholds and privacy-conscious sightlines.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside Harbor Wellness Therapy in polished painterly semi-realistic grounded mature contemporary cinematic realism. Continue the St. Maren campus with warm off-white and oatmeal walls, muted sage and dusty-teal upholstery, weathered walnut furniture and acoustic slats, pale stone, soft charcoal carpet, frosted privacy glass, abstract coastal art without faces, indoor plants, cool coastal daylight, and warm shaded or indirect lamps. Make the practice calm, confidential, inclusive, accessible, professionally maintained, residential in warmth, and clearly non-clinical. Preserve exactly the authored routes, distinguish public reception and waiting from appointment-only rooms, and keep the lower center useful for dialogue UI. No people, staff, clients, figures, silhouettes, reflections of figures, photographic faces, navigation arrows, interface, readable words, letters, numbers, room names, patient names, notices, schedules, worksheets, forms, notes, folder labels, calendars, signs, logos, brands, active screens, clocks, medical equipment, medication, anatomy art, blood, injuries, bodily fluids, weapons, clutter, extra routes, stairs, steps, raised thresholds, fisheye distortion, or watermark; all screens, papers, files, folders, cabinets, panels, signs, and labels must be blank, dark, closed, face-down, abstract, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Reception | `harbor_wellness_therapy/reception.png` | Walnut-and-pale-stone desk with two blank monitors, frosted foreground Wellness Walk doors, one right Waiting Lounge route, plants, and clear staging. |
| Waiting Lounge | `harbor_wellness_therapy/waiting_lounge.png` | Residential seating clusters around a four-way hub: left Reception, rear Individual Office, right Relationship Counseling Office, and foreground Group Room passage. |
| Individual Therapy Office | `harbor_wellness_therapy/individual_office.png` | Private two-armchair counseling layout with small round table, discreet writing desk, closed records, acoustic treatment, and one lower Waiting Lounge return. |
| Relationship Counseling Office | `harbor_wellness_therapy/couples_office.png` | Neutral loveseat and separate therapist chair in a three-person arrangement with circular rug, closed storage, and one left Waiting Lounge return. |
| Group Room | `harbor_wellness_therapy/group_room.png` | Ten upholstered chairs in an open circle, acoustic panels, closed materials cabinet, level floor and threshold, and one centered rear Waiting Lounge return. |

### St. Maren Sexual Health Centre batch prompt set

This four-room batch establishes a privacy-first adult health service connected discreetly
to Wellness Walk. It remains inclusive, respectful, and entirely non-graphic: Reception
uses separated screened seating, Consultation handles conversation and referrals, and the
Testing and Treatment rooms use distinct collection-chair and exam-table layouts. Records,
supplies, medication, testing materials, and identifying information remain closed away.

Shared prompt specification:

> Use case: stylized-concept. Asset type: production 16:9 visual-novel environment background for the Godot game Port Alder. Create the named mapped destination inside St. Maren Sexual Health Centre in polished painterly semi-realistic grounded mature contemporary cinematic realism. Continue the St. Maren campus through warm off-white walls, pale limestone, sea-green privacy glass, deep muted-teal upholstery, weathered walnut, charcoal resilient flooring or quiet carpet tile, restrained muted-plum accents, abstract coastal art without faces, indoor plants, cool coastal daylight, and warm indirect lamps. Make the adult service calm, discreet, inclusive, accessible, confidential, clinically believable, dignified, non-judgmental, non-erotic, and completely non-graphic. Preserve exactly the authored routes, distinguish private reception and consultation from appointment-only testing and treatment, and keep the lower center useful for dialogue UI. No people, staff, patients, figures, silhouettes, reflections of figures, photographic faces, navigation arrows, interface, readable words, letters, numbers, room names, health messages, patient names, notices, schedules, forms, charts, records, folder labels, calendars, signs, logos, brands, active screens, clocks, anatomical or sexual imagery, contraception products, visible test kits, sample containers, specimens, swabs, exposed medication, needles, syringes, blood, injuries, bodily fluids, treatment in progress, weapons, clutter, extra routes, stairs, steps, fisheye distortion, or watermark; all screens, papers, files, folders, cabinets, equipment, panels, signs, and labels must be blank, dark, closed, locked, capped, sealed, face-down, abstract, or too indistinct to read.

Destination-specific briefs:

| Destination | Production file | Brief |
| --- | --- | --- |
| Private Reception | `st_maren_sexual_health/private_reception.png` | Deep-teal-and-walnut counter, blank monitors, screened individual seating, frosted foreground Wellness Walk doors, and one right Consultation route. |
| Consultation Room | `st_maren_sexual_health/consultation_room.png` | Three-way conversation hub with round table, private desk, left Reception, right Testing Room, and open foreground Treatment Room route. |
| Testing Room | `st_maren_sexual_health/testing_room.png` | Non-graphic collection room with upright adjustable chair, privacy screen, sink, blank monitor, closed supplies, and one left Consultation return. |
| Treatment Room | `st_maren_sexual_health/treatment_room.png` | Distinct outpatient room with horizontal exam table, visitor chair, folded screen, sink, blank monitor, closed supplies, and one centered rear Consultation return. |

## Opening production references

### Hale Home — Player Bedroom

Saved as `res://assets/art/backgrounds/hale_home/player_bedroom.png`.

Prompt:

> Use case: stylized-concept. Asset type: production visual-novel room background for a Godot game. The 18-year-old male player's bedroom in the Hale family home on a late-August Tuesday morning, just before his mother enters to discuss his future. A comfortable, lived-in upstairs bedroom in a middle-class Port Alder home: young-adult rather than childish, with a bed, bedside table, modest desk, dresser, wardrobe or closet, coastal window, and a visible doorway for a character entrance. Polished grounded semi-realistic 2D visual-novel illustration with painterly surfaces and restrained clean linework. Eye-level 16:9 composition, believable geometry, open character staging, and a calm darker lower 35 percent for dialogue. Soft cool coastal morning light, warm wood, slate blue, muted teal, cream, and rust. No people, sprites, arrows, UI, text, logos, watermark, or fisheye distortion.

### Elena Reyes-Hale — Default / Neutral

Saved as `res://assets/art/characters/elena_reyes_hale/default.png`.

Prompt:

> Use case: stylized-concept. Asset type: production visual-novel transparent character portrait. Elena Reyes-Hale, age 45, the player's mother and a clinic administrator: protective, organized, direct, maternal, warm, and quietly stubborn. A believable middle-aged woman with medium warm olive skin, brown eyes, shoulder-length dark chestnut hair with subtle silver strands, mature features and natural smile lines, and an attentive neutral expression. Practical muted-teal blouse, warm-rust cardigan, tailored charcoal trousers, and simple jewelry. Grounded semi-realistic contemporary-drama illustration with painterly materials and restrained linework. Tall centered standing portrait, head to below the knees, natural hands and silhouette, soft coastal morning light, genuinely transparent background. Age-accurate, non-sexualized, and free of text, logos, props, scenery, borders, or watermark.

## Provenance

The baseline assets and all fifty-two room batches were generated with the built-in
OpenAI image-generation tool during 2026-08-29 and 2026-08-30 for the Port Alder project. They are
original project assets intended for redistribution and modification with the
game. Source generations remain in the local Codex generated-image store; the
checked-in PNG files are the canonical game copies.
