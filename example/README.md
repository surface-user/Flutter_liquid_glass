# Material lab

Interactive gallery for lightweight_liquid_glass. Run commands from this directory:

```sh
flutter pub get
flutter run -d edge
flutter test
flutter build web --release
```

Android uses the stock Java Flutter embedding. No platform-specific glass rendering.
Gallery screenshots are in `test/goldens`; the gallery entry is `lib/main.dart`.

Run the standalone [layout recipe](lib/recipes/layout_recipe.dart) with
`flutter run -t lib/recipes/layout_recipe.dart`. Its header wraps at narrow
widths, and the same Flutter cards sit inside either a solid `Material` panel
or a single optional `GlassSurface`. The recipe uses only Flutter and the
library's public entry point.

Run the standalone [workbench recipe](lib/recipes/workbench_recipe.dart) with
`flutter run -t lib/recipes/workbench_recipe.dart`. The sidebar and closable
tabs use sample sections. Switch the preview between Solid, Glass and No blur;
the draft stays in the input. Apply draft opens a confirmation dialog and only
updates the preview after confirmation. The original gallery is unchanged.

