---
name: philo-grid-system
description: Define, implement, extend, and maintain the PhiloGrid System for dynamic, responsive UI card and matrix layouts in PhiloEngine. Use when working on Flutter or web grid views, card matrices, dashboards, adaptive multi-column layouts, or visual grid overlays.
---

# PhiloGrid System Specification & Skill

Use the **PhiloGrid System** as PhiloEngine's core layout matrix and component
alignment pattern.

## Apply adaptive column delegation

- Use dynamic constraints such as `SliverGridDelegateWithMaxCrossAxisExtent` or
  custom aspect-ratio delegates to adapt from narrow panes to wide desktop
  grids.
- Use 12px or 16px padding and 8px or 12px cross-axis spacing.

## Build decoupled cells with the PhiloGrid Tile Engine

- Build each grid element from modular, reusable card builders.
- Apply fixed or flexible height ratios that prevent overflow and text clipping.

## Paint visual matrices

- Use restrained canvas grid lines or low-key pixel grids for plots, execution
  traces, and visual reasoning blocks.
- Keep data-to-grid mapping separate from painting and layout decisions.
