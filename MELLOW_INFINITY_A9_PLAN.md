# Mellow Infinity A9 Plan

## Target

Mellow Infinity A9 is an Adreno 619-first redesign for the Samsung Galaxy Tab A9+ (SM-X210), Snapdragon 695, Android OpenGL ES, Minecraft Java 1.20.1, Iris/Oculus, and Zalith Launcher.

The goal is not maximum PC fidelity. The goal is maximum beauty per GPU cycle on this exact tablet.

## Execution order

1. **Protect frametime first**
   - Default to 60 FPS-friendly settings.
   - Reduce full-screen pass count before adding visual effects.
   - Prefer compile-time profile switches over runtime branches.

2. **Replace expensive atmosphere with gradients**
   - Keep sky color, golden hour, and night mood in cheap gradient math.
   - Keep clouds as flat layered procedural coverage by default.
   - Reserve volumetric-style work only for Showcase.

3. **Rewrite lighting around cheap perceptual wins**
   - Preserve warm sunrise/sunset color and richer night ambiance.
   - Improve torch and cave feel with lightmap shaping, not extra passes.
   - Use PBR features only when they justify their texture fetch cost.

4. **Make shadows stable, not overfiltered**
   - Balanced mode should use a tiny fixed kernel.
   - Visual/Showcase may increase filtering, but no large kernels or contact shadows.
   - Fade shadow work by distance and skylight where possible.

5. **Redesign water without SSR dependency**
   - Default water should reflect sky and sunlight by approximation.
   - Use normal-map waves only when the selected A9 mode can afford them.
   - Keep SSR off for Eco/Balanced because it adds loops and depth fetches.

6. **Validate every step statically**
   - Track loop counts, texture calls, and mode-gated pass changes.
   - Treat desktop regressions as acceptable if Adreno stability improves.

## A9 quality tiers

| Tier | Purpose | Default stance |
| --- | --- | --- |
| A9 Eco | Battery and thermals | No bloom, no SMAA/TAA, no SSR, no water normals, minimal shadows. |
| A9 Balanced | Default target | Flat procedural clouds, cheap sky reflection water, small shadow kernel, no heavy full-screen extras. |
| A9 Visual | Better screenshots while playable | Bloom, water normals, modest filtering, still no SSR by default. |
| A9 Showcase | Push hardware briefly | Optional heavier AA/SSAO/SSR features for screenshots or short sessions. |

## First implementation slice

This first slice establishes the plan, adds explicit A9 profiles, and replaces high-cost defaults with Adreno-friendly approximations in the shared shader code. Later slices should continue with deeper pass removal and more targeted color/lighting tuning after device-side profiling.
