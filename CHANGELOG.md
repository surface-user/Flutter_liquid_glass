## Unreleased

- Add explicit inherited theme merging, geometry/typography/semantic-color configuration, state-aware control styles and opt-in compact density while preserving legacy default visuals.
- Apply theme geometry and motion to existing controls, cards, dialogs, app bars and animated surfaces. Preserve external focus ownership and dialog Esc/focus behavior.
- Keep blur sigma discrete and restrictive accessibility/performance policies active during theme interpolation; high contrast overrides decorative foreground/fallback colors.

- Separate core rendering/configuration, themes and component modules; remove the theme/route dependency cycle. Preserve all twenty public declarations, defaults and visual baselines through the existing entry point.

- Add pointer-following rim highlights with repaint-only tracking and accessibility/low-quality fallback.

- Add an SDK-only example Android profile sampler with raw frame timings and tested percentile summaries. Hardware measurements remain required.

- Preserve gesture cleanup when reduced-motion settings change during a press.

- Add shared press, hover and keyboard focus feedback to buttons, icon buttons and tappable cards without changing public APIs or blur radii.
- Respect all reduced-motion switches and isolate animated backdrop inputs.

## 0.1.0

- Initial pure Flutter glass surface, immutable styles and seven presets.
- ThemeExtension and local theme overrides; high contrast and reduced transparency fallback.
- Grouped, bounded backdrop filters with nested and differing-filter isolation.
- Cards, keyboard-accessible buttons, app bar, scrollable dialog and five page transition styles.
- Explicit quality limits; static-by-default procedural background and optional bounded noise.
- Interactive responsive gallery, style/widget tests and visual regression baselines.

