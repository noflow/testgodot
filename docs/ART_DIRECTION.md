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

The twenty-six completed base-art locations are the Hale Home, Alder Heights Residential
Street, Alder Heights Bus Stop, Westshore Administration Office, Harbor Employment
Centre, Alder Bay Park, Harborlight Cinema, Forge Fitness, Westshore Campus, and
Bayview Café, plus Port Alder Marina, Alder Bay Beach, Port Alder Galleria, Harbor Centre
Downtown, Harbor Centre Apartments, Harbor View Condominiums, Port Alder Credit
Union, Port Alder City Hall, Port Alder Realty, Harbor Centre Business Services,
Cypress Hall Dorm, Maple Hall Dorm, the Westshore Shared Student Apartment, and the
Westshore Bookshop, Lantern Gallery, and Lantern District Street. Together they provide
140 unique base-day PNG
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

The baseline assets and all twenty-one room batches were generated with the built-in
OpenAI image-generation tool on 2026-08-29 for the Port Alder project. They are
original project assets intended for redistribution and modification with the
game. Source generations remain in the local Codex generated-image store; the
checked-in PNG files are the canonical game copies.
