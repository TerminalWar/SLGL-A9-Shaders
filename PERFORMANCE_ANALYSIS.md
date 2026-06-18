# Mellow Infinity A9 Performance Analysis

Target device: Samsung Galaxy Tab A9+ SM-X210, Snapdragon 695 / Adreno 619, Android OpenGL ES, Minecraft Java 1.20.1 through Iris/Oculus on Zalith Launcher.

## Method

This is a static first-pass audit before functional rewrites. I ranked files by expected Adreno 619 cost using:

- full-screen pass frequency;
- texture fetch count;
- loop count and dynamic loop risk;
- branch/preprocessor complexity;
- framebuffer and bandwidth pressure;
- mobile relevance.

The ranking is intentionally Adreno-first. Desktop-only features and compatibility paths are treated as negative value when they increase shader size, compile pressure, or memory footprint for mobile users.

## Highest-impact bottlenecks

| Rank | Area / file | Expected FPS impact | Why it matters on Adreno 619 | Direction |
| --- | --- | ---: | --- | --- |
| 1 | `shaders/global/post/taa.glsl` | Very high | Full-screen temporal pass with multiple texture reads, branch paths, and reprojection math. It runs where bandwidth is already stressed. | Keep only if it visibly stabilizes; simplify history sampling and cut compatibility paths. |
| 2 | `shaders/global/post/smaa.glsl` plus `smaaArea.png` / `smaaSearch.png` | Very high | SMAA costs multiple full-screen passes and lookup textures. Good quality, but expensive for a tablet when resolution is high. | Make mode-dependent; Eco/Balanced should prefer cheaper AA or no AA. |
| 3 | Bloom chain: `composite2` through `composite7`, `shaders/global/post/bloom.glsl` | Very high | Repeated downsample/blur passes increase bandwidth and framebuffer traffic. | Reduce pass count and resolution; clamp to Visual/Showcase where needed. |
| 4 | `shaders/global/shadows.glsl` | High | Shadow sampling is texture-fetch heavy and sensitive to cache/bandwidth. PCF-style softness is costly on Adreno. | Use small fixed kernels, distance fading, and stable low-cost biasing. |
| 5 | `shaders/global/sky.glsl` | High | Procedural sky/cloud logic includes loops and multiple texture/noise paths. It can be cheap if gradient-driven, expensive if cloud-heavy. | Replace expensive cloud systems with layered gradients/procedural approximations. |
| 6 | `shaders/global/water.glsl` and water gbuffers | High | Water often combines lighting, normals, transparency, fog, and reflection-like work. | Replace SSR/ray-style logic with sky-color reflection, cheap waves, and depth tint. |
| 7 | `shaders/program/gbuffers_terrain.fsh` | High | Terrain is the most frequently shaded world surface. PBR/POM paths, end portal logic, and DH conditionals increase cost. | Simplify PBR defaults, ensure POM is off by default, and remove mobile-irrelevant support. |
| 8 | `shaders/lib/distant_horizons.glsl` | Medium-high | Additional depth textures and conditional depth paths add fetches/branches. Useful only when the launcher stack can run it acceptably. | Keep optional but isolate from the mobile default path. |
| 9 | `shaders/global/fog.glsl` | Medium-high | Fog is visually important but has loop/branch-heavy logic. | Replace with exponential and height approximations; no volumetrics. |
| 10 | `shaders/global/pbr.glsl` | Medium | Normal/specular decoding costs texture reads. PBR quality helps visuals but is expensive when enabled broadly. | Use cheap approximations; default to low-cost material response. |

## Most expensive files by static indicators

Static scan counted loops, branch sites, texture calls, and line count in GLSL/FSH/VSH files. The highest-scoring files were:

1. `shaders/global/post/taa.glsl` — temporal reprojection, texture reads, loop/branch complexity.
2. `shaders/lib/distant_horizons.glsl` — depth-path branching and extra depth texture reads.
3. `shaders/global/post/smaa.glsl` — four loops and multiple texture reads across full-screen AA work.
4. `shaders/program/gbuffers_terrain.fsh` — terrain hot path with POM loop and texture reads.
5. `shaders/global/water.glsl` — branch-heavy water shading.
6. `shaders/global/sky.glsl` — procedural sky/cloud loops and texture reads.
7. `shaders/global/shadows.glsl` — shadow lookups and filtering.
8. `shaders/global/post/bloom.glsl` — full-screen multi-fetch blur/downsample work.
9. `shaders/global/fog.glsl` — branch/loop-heavy atmospheric work.
10. `shaders/lib/noise.glsl` — repeated noise texture/function use can become expensive when called inside hot paths.

## Texture bottlenecks

- Full-screen post effects are the biggest bandwidth risk: TAA, SMAA, bloom, DOF, chromatic aberration, SSAO, and CAS all compete for the same limited memory bandwidth.
- `smaaArea.png` and `smaaSearch.png` add lookup texture pressure for anti-aliasing.
- `cloud_noise+normal.png` and `worley_perlin.bin` are visually useful but must not be sampled heavily in hot full-screen or terrain paths.
- PBR paths can add normal/specular fetches per terrain fragment. These should be optional and disabled by default for A9 Eco/Balanced.
- Distant Horizons depth textures add extra depth reads. This is acceptable only when the mode and launcher stack justify it.

## Memory and framebuffer bottlenecks

- Bloom's multi-pass chain is likely the largest framebuffer traffic source.
- SMAA uses multiple full-screen passes and lookup textures.
- TAA needs history/color/depth sampling and reprojection data.
- Extra support files for non-mobile systems increase pack size and shader compile scope. Voxy support is not appropriate for the target mobile configuration and should be removed.

## Branch-heavy code

Branch-heavy areas that should be simplified first:

- `shaders/global/water.glsl`
- `shaders/global/fog.glsl`
- `shaders/global/lighting.glsl`
- `shaders/program/gbuffers_terrain.fsh`
- `shaders/lib/distant_horizons.glsl`

Adreno generally benefits from predictable, compile-time mode selection over runtime branching. Prefer `#if` mode gates and low-variant defaults.

## Loop-heavy code

Loop-heavy areas that should be constrained or replaced:

- `shaders/global/post/taa.glsl`
- `shaders/global/post/smaa.glsl`
- `shaders/global/sky.glsl`
- `shaders/global/water.glsl`
- `shaders/global/fog.glsl`
- `shaders/program/gbuffers_terrain.fsh` POM path

Dynamic loops should be avoided. If loops remain, keep them fixed, tiny, and mode-gated.

## Immediate mobile-first actions

1. Remove Voxy support files and conditionals. Voxy is not a realistic target for Zalith/mobile users and costs pack size, compile complexity, and maintenance.
2. Define A9 quality tiers: Eco, Balanced, Visual, Showcase.
3. Make Bloom/SMAA/TAA mode-dependent rather than always assumed.
4. Rewrite sky/fog/water around gradients and cheap approximations.
5. Rework shadows around small fixed kernels, stable bias, and distance simplification.
6. Keep Distant Horizons optional but outside the mobile default path.

## First-pass conclusion

The current shader has strong visual foundations but still contains PC-oriented compatibility and feature paths. The best early win for Mellow Infinity A9 is to reduce full-screen pass pressure and remove unsupported systems like Voxy before rewriting lighting, sky, fog, water, and shadows for Adreno 619.
