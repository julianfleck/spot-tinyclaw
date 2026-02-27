# SVG Diagram Generator

Generate minimalist conceptual diagrams in SVG format for articles and documentation.

## Style Guide

**Visual Language:**
- Stark minimalist, white on black (dark mode primary)
- Light mode: invert to black on white
- Clean 1-2px strokes, no fills
- Small caps geometric sans-serif (e.g., "DECAY", "VALUE")
- Centered composition with generous negative space
- Geometric primitives as visual metaphor

**Elements:**
- Circles, lines, curves, rectangles
- Connecting lines (solid or dashed)
- Simple labels in small caps
- No gradients, shadows, or decorative elements
- Aspect ratio: 16:9 (1280×720) or square (800×800)

**Reference images:** `~/.openclaw/skills/svg-diagrams/references/`

## Usage

### Generate from concept

Given an article or concept, identify the key visual metaphor and create an SVG:

```bash
# Example prompt to the model:
"Create an SVG diagram illustrating [concept] in the minimalist style.
- Dark mode (white on black)
- 1280x720 viewport
- Use geometric primitives
- Labels in small caps"
```

### Dual mode output

Always generate both:
1. `{name}-dark.svg` - white strokes on black background
2. `{name}-light.svg` - black strokes on white background

### SVG Template

```svg
<svg viewBox="0 0 1280 720" xmlns="http://www.w3.org/2000/svg">
  <!-- Dark mode: white on black -->
  <rect width="100%" height="100%" fill="#000"/>
  <g stroke="#fff" stroke-width="1.5" fill="none">
    <!-- Diagram elements -->
  </g>
  <text fill="#fff" font-family="system-ui, sans-serif" 
        font-size="14" letter-spacing="0.15em">
    <!-- Labels in small caps (use text-transform or uppercase) -->
  </text>
</svg>
```

## Common Patterns

### Comparison (before/after, A vs B)
Two elements side by side with labels below. See `06-content-context.jpg`.

### Progression/Gradient
Horizontal sequence showing change. See `03-progressive-density.jpg`.

### Hierarchy/Tree
Connected boxes or nodes. See `05-hierarchy-tree.jpg`.

### Curves/Relationships
Mathematical curves with labeled axes. See `01-price-value-curve.jpg`.

### State/Oscillation
Visual representation of dynamic state. See `02-waveforms.jpg`, `04-circle-helix.jpg`.

## For RAGE Articles

Suggested diagrams for the 2026-rage-evolution series:

### "From Graphs to Fields"
- Graph nodes → continuous field gradient
- Discrete points morphing into wave patterns

### "Decay is a Feature"
- Active → dormant → archived state progression
- Entropy/fading visualization

### "Phase Signatures"
- Phase angles on unit circle
- Oscillator synchronization (in-phase vs out-of-phase)
- Coupling/interference patterns

## Output

Save SVGs to: `~/.openclaw/workspace/repos/writing/articles/2026-rage-evolution/assets/`

Both dark and light variants for each concept.
