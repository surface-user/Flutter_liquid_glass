## Unreleased

- Honor the platform's separate reduce-motion flag for glass surfaces, optional backdrop animation and newly opened glass routes with a source context.
- Finish active `AnimatedGlassSurface` transitions immediately when motion is reduced, preserving child state and focus.
- Add a controlled `NavigationItem` for regular and glass surfaces, with keyboard activation and selected semantics.
- Add a controlled `NavigationTab` with tab semantics and an optional, independently focusable close button.
- Add global and per-subtree navigation item color overrides for the selected background and focus border.
- Add `ActionButton` and `IconActionButton` with common variants, sizes and scoped styling, plus an app-controlled loading state that retains focus and layout.

## 0.1.0

- Initial pure Flutter glass surface, immutable styles and seven presets.
- ThemeExtension and local theme overrides; high contrast and reduced transparency fallback.
- Grouped, bounded backdrop filters with nested and differing-filter isolation.
- Cards, keyboard-accessible buttons, app bar, scrollable dialog and five page transition styles.
- Explicit quality limits; static-by-default procedural background and optional bounded noise.
- Interactive responsive gallery, style/widget tests and visual regression baselines.

