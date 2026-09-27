# TrailPath — Reference Apps UX Benchmark 2026

Benchmark date: 2026-09-26  
Scope: mobile outdoor route planning, destination selection, map-space usage, waypoint editing and interaction fluidity.

This benchmark is intentionally **UX-only**. TrailPath remains a focused utility; social/community feeds, public-route marketplaces, challenges and other unrelated product scope are not imported.

## Current TrailPath findings

The current planner confirms the physical feedback:

- the full `_PlannerCard` is always rendered at the bottom, even with zero points;
- the card contains title, hints, activity profiles, three metrics, routing state, elevation, GPS state and action rows, so it occupies a large portion of the map;
- `onMapClick` directly calls `_addWaypoint(coordinates)`, so a normal tap immediately changes route state;
- a searched place is handled differently: it creates/focuses a separate search marker but does not enter the same route-point selection state;
- route/waypoint/midpoint annotations are updated through multiple sequential MapLibre annotation calls, which is a plausible contributor to interaction jank under repeated redraws.

## Reference: Komoot

Current 2026 direction:
- Android Route Planner rebuilt with a cleaner layout;
- smoother editing;
- simpler waypoint management;
- explicit start/destination semantics;
- route line and waypoints remain directly editable.

What TrailPath should take:
- explicit user intent after selecting a point;
- clear distinction between start, destination and intermediate waypoint;
- direct manipulation of route/waypoints;
- minimal map obstruction while editing.

What TrailPath should not copy:
- account/community/product complexity unrelated to the utility goal.

## Reference: AllTrails

Current mobile Custom Routes pattern:
- tap the map to set the first point and continue building the route;
- route points can be tapped and dragged;
- routing options live in a compact map control;
- detailed route visualisation is reached by swiping up a bottom panel rather than permanently consuming the map.

What TrailPath should take:
- **progressive bottom sheet** instead of a permanently expanded summary;
- map as the dominant workspace;
- compact state for essentials, expanded state for details;
- editing tools contextual to the selected point/route.

TrailPath adaptation:
- unlike AllTrails' simple sequential tap model, TrailPath should add a preview/confirm step because physical testing already shows accidental/incorrect destination selection.

## Reference: Wikiloc

Current app planner pattern:
- starting point can come from either map tap or search;
- subsequent points can also come from map or search;
- the same planning flow handles both input methods;
- activity selection is part of the planning workflow.

What TrailPath should take:
- one canonical point-selection pipeline shared by map and search;
- no separate semantics where search only centers a marker while map tap mutates the route;
- activity profile remains available but should not permanently occupy map space before it is needed.

## Reference: Organic Maps

Current 2026 Android direction:
- redesigned Search UI/UX;
- redesigned route-planning interface;
- strong offline-first and privacy-first posture;
- map remains visually primary;
- alternate routes and route warnings are presented contextually rather than as permanent heavy panels.

What TrailPath should take:
- lightweight search/planning chrome;
- contextual route information;
- preserve TrailPath's local-first/offline philosophy.

## Target TrailPath interaction model

### State 0 — empty planner
- Full-screen map.
- Search at top.
- Recenter plus only essential planning controls.
- No full summary card.
- Activity profile available through a compact control, not a large permanent panel.

### State 1 — point preview
A map tap, search result or POI selection creates the same temporary candidate pin.

The candidate does **not** mutate the route until confirmed.

Context actions:
- Start here;
- Destination;
- Add waypoint, when a route already exists;
- Cancel.

Camera padding must keep the candidate pin visible above the compact confirmation sheet.

### State 2 — start confirmed, destination missing
- Keep map dominant.
- Show a compact bottom prompt such as “Choose destination”.
- No elevation panel or full metrics block yet.

### State 3 — valid route
After destination confirmation:
- show compact bottom sheet with distance, ETA, ascent and primary Save/Start action;
- allow swipe/drag upward to expose activity profile, elevation, GPX/share and secondary controls;
- keep the collapsed height small enough that most of the screen remains map.

### State 4 — route editing
- tapping a waypoint selects it without creating another waypoint;
- dragging updates preview smoothly and reroutes only when appropriate;
- tapping empty map enters candidate-preview mode instead of immediately changing the route;
- route-line interaction can offer “add waypoint here” contextually;
- undo/redo remain immediately accessible while editing.

## Fluidity work package

1. Measure physical frame timing before changing architecture.
2. Prevent whole planner UI rebuilds for transient map-only state where possible.
3. Coalesce annotation synchronization into one scheduled frame/task.
4. Do not sequentially rewrite every route/waypoint annotation when only one item changed.
5. Investigate MapLibre style sources/layers for high-frequency route geometry and static markers; reserve interactive annotations for draggable/selectable handles.
6. Keep route calculation/elevation/network work off the gesture-critical path.
7. During drag, render a local lightweight preview; reroute after drag end or a controlled debounce.
8. Cache route/elevation presentation data already available instead of recalculating purely visual derivatives.
9. Establish physical-device targets for startup, pan/zoom, waypoint drag and destination confirmation.
10. Add regression tests for hidden/compact/expanded planner states and canonical map/search destination selection.

## Release acceptance criteria for this UX pass

- empty planner shows no permanent full summary card;
- a destination cannot be added accidentally by a normal exploratory tap without confirmation;
- map tap and search result use the same selection state machine;
- selected point appears at the intended coordinate and remains visible when the bottom sheet opens;
- route summary appears only after meaningful route state exists;
- waypoint editing remains functional;
- physical-device interaction is visibly smoother than build 30 and no reproducible severe jank is accepted;
- API 29 + API 35/AppLab + focused offline tests remain green after implementation.
