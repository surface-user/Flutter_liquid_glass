# Public demo

URL: https://lightweight-liquid-glass-lab.marseille-cjh.chatgpt.site

Published successfully through Sites on 2026-09-17. Audience: public.
The demonstration runs in the visitor's browser; it does not need the author's
computer or local preview server to stay online.

The hosting checkout is deployment/site/ and its persisted Site identity is in
deployment/site/.openai/hosting.json. Reuse it for future deployments.
This local deployment checkout and its archives are excluded from the library
repository and pub package. The library's GitHub remote remains unchanged.

The deployed static files come from example/build/web. The deployment bootstrap
loads CanvasKit from its own canvaskit/ directory and disables the deprecated
service-worker bootstrap. Keep this configuration when refreshing the demo.

For later updates: rebuild the Flutter example, update this same static checkout,
then follow the Sites hosting workflow to publish a new version to this URL.
