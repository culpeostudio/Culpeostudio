---
name: rosetta-grid-system
description: Framework guidelines and design pattern specifications for implementing, extending, and maintaining the Rosetta Grid System for dynamic, responsive UI card and matrix layouts in PhiloEngine.
whenToUse: Use when working on UI layouts, grid views, card matrices, or dashboard screens in PhiloEngine.
---

# Rosetta Grid System Specification & Skill

The **Rosetta Grid System** is the core layout matrix and component alignment engine used in PhiloEngine.

## Core Concepts of Rosetta Grid

1. **Adaptive Column Delegation**
   - Uses dynamic constraints (`SliverGridDelegateWithMaxCrossAxisExtent` or custom aspect-ratio delegates in Flutter) to adapt seamlessly from mobile/narrow panes to wide desktop grids.
   - Standard grid gaps: 12px / 16px padding, 8px / 12px cross-axis spacing.

2. **Decoupled Grid Cells (Rosetta Tile Engine)**
   - Every grid element must inherit from modular, reusable card builders.
   - Enforce fixed/flexible height ratios to prevent dynamic overflow or text clipping inside grid cells.

3. **Visual Matrix & Custom Painting**
   - Supports background grid overlays (visual canvas grid lines, low-key pixel grids) for technical visual blocks (e.g., plot grids, execution traces, visual reasoning blocks).
