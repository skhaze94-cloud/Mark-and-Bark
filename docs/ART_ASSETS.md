# Mark & Bark — Detailed Raster Asset Pack

Start by opening **catalogue.html** after extracting this ZIP. It runs offline and lets you browse, filter and download the individual assets. Read **asset_manifest.json** for filenames, crop rectangles, dimensions, pivots and preview frame orders. A flat inventory is in **docs/asset_inventory.csv**.

## Included

| Asset family | Unique assets |
|---|---:|
| Young Mark, Middle Mark, Teen Mark and Bark — eight directional views each | 32 |
| Young Mark, Middle Mark and Bark — twelve action key poses each | 36 |
| Teen Mark — six core action key poses | 6 |
| Collectibles and inventory items | 12 |
| School and nature props | 12 |
| HUD panels, icons and chapter tiles | 12 |
| Detailed material color tiles | 24 |
| School, garden and neighbourhood backdrops | 3 |
| **Total unique game assets** | **137** |

The pack also includes 18 generated master images, the eight original concept images, 74 additional character exports on consistent 512×640 canvases, contact sheets, material repeat previews, and implementation metadata. Native material tiles are 512×512. Environment images are 1672×941. Master sprite sheets are approximately 1.5K wide; individual native sprites retain their original raster detail. Resizing the normalized exports does not add source detail. The three flattened backdrops are counted among the 18 masters and are stored once in environments/.

## Fast implementation

1. For characters, import PNGs from **characters/<character>/sprites/**. All of these use a 512×640 transparent canvas with their foot anchor at **(256, 612)** measured from the top-left. Bottom-left normalized pivot is **(0.5, 0.04375)**. Use the provided value consistently rather than a default center pivot.
2. For original detail and custom alignment, use **characters/<character>/native/**. Their individual pivots are in the manifest. Each sheet uses one uniform normalization scale, preserving pose proportions. A wide pose may limit that sheet's scale, so review transitions between turnaround and action sets.
3. Props, collectibles and HUD elements are in **props/** and **ui/**. They are tightly cropped transparent images. Choose a centered pivot for inventory/HUD use and the provided foot pivot for world props. Add gameplay collision shapes independently of the painted silhouette.
4. Material PNGs are in **materials/tiles/**. Treat them as sRGB color textures. Start with metallic 0 and the roughness hint in the manifest. They are stylized painted surfaces, not measured PBR scans. There are no normal, height, roughness, occlusion or metallic image maps.
5. Use a **mirrored-repeat** sampler for these materials. Ordinary-repeat seams are not certified. **docs/repeat_previews/** shows ordinary 2×2 repeat on the left and mirrored 2×2 repeat on the right. Mirroring removes value jumps at copy boundaries; repeated motifs and reflected structure still need review. The small GLSL helper in **docs/mirrored_uv.glsl** shows equivalent UV folding when a sampler setting is unavailable.
6. The three **environments/** images are flattened backdrops. Overlay sprites and props; build separate invisible walkways, interaction points and collision shapes. They do not contain independent parallax layers or walkable 3D geometry. Keep a clear playable lane and do not infer collision from painted furniture, bridges or stumps.
7. Add all readable UI words and signs as engine text. The blank panels support localisation. The generated progress track has an opaque navy interior: draw your fill over it, then overlay the frame/track as appropriate to your HUD construction.

## Poses and angles

Direction order is front, front-right, right, back-right, back, back-left, left, front-left. These describe the direction the character faces as seen on screen. Individual files are named explicitly. Use native or normalized exports for implementation rather than slicing masters into equal cells: some poses and props exceed their nominal cell edges. The manifest's rectangles and the isolated exports handle those overlaps.

Young Mark, Middle Mark and Bark have walk/run key-pose preview sequences in the manifest. They show motion intent, not finished production cycles. Some strides do not alternate legs cleanly; stance, size, costume detail and facial shape can drift slightly. An animator should add in-betweens, lock contact feet, align hips and polish timing before shipping. Teen Mark has one pose each for idle, walk, run, jump, crouch and reading; he has no walk/run loop in this pack. Paper-plane gameplay can begin with Young or Middle Mark's throwing pose and the separate plane prop.

## Story chapters

These age bands describe **Mark's age in the story**, rather than a certified audience rating. Keep the full game child-friendly even in later chapters.

| Chapter | Mark's age | Play spaces | Play focus |
|---|---|---|---|
| Early Years | 7–9 | Garden, treehouse, home street | Discover leaves, fold planes, help Bark find clues |
| Middle School | 11–13 | School hub, classroom, garden | Notebook puzzles, science projects, cooperative errands |
| High School | 16–17 | School, neighbourhood, community garden | Build inventions, mentor friends, repair earlier mistakes |

Difficulty can increase through longer puzzles and more independent choices. Offer optional hints and forgiving retries at every stage. Reward creativity, teamwork and thoughtful choices; use comic, repairable consequences for mistakes. Bark can suggest amusing shortcuts while a thoughtful route remains available. An open-world structure can start as three connected hubs and grow into more routes rather than needing a huge map immediately.

Suggested first playable quest: arrive at school, meet Bark, collect a notebook page, find three leaf clues in the garden, send a paper plane to a puzzle target, and return to the classroom science table. Use clear pictorial objectives and a friendly finish animation.

## What remains for a full game

This is a substantial visual starter pack for a 2D prototype and a reference package for 3D production. It does not include gameplay code, complete animation cycles, all states in every direction, 3D meshes or rigs, model-fitted UV textures, skeletal animation, audio, or a complete open-world map. Existing models and their UV layouts are needed to make fitted 3D texture sets. A later animation pass should cover climb, interact, land, turn, facial dialogue and age-specific transitions.

## Source and generation

The supplied Mark & Bark concept pack is preserved in **source_concepts/**. The title follows the attached source. New art was produced with built-in imagegen from those references, keeping the navy/gold/oak/moss palette. The middle-school design is a new bridge between the supplied young and teen designs. **docs/generation_records.json** contains art direction and the recorded full prompts for the materials, Teen Mark core poses, environments and HUD set.

Native objects were mechanically separated using transparency components; RGB and alpha were retained around the selected object with a small edge-support margin. Normalized character exports use uniform resampling and padding. Contact sheets are review aids. There has been no invented PBR-map derivation. Inspect **docs/quality_report.json** for extraction and edge statistics, and **docs/verification.json** for file checks.
