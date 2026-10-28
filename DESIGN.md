---
name: METATRON
description: Utilidad nativa de archivos con identidad geométrica
colors:
  petroleum: "#234A60"
  petroleum-source: "#365D72"
  forest: "#305340"
  graphite: "#3D4650"
  slate: "#3F5574"
  burgundy: "#683F4F"
  brand-navy: "#111B26"
  brand-ivory: "#E8E6D9"
  brand-teal: "#82B4C4"
typography:
  title:
    fontFamily: "SF Pro, system"
    fontSize: "25pt"
    fontWeight: 600
rounded:
  panel: "12pt"
spacing:
  section: "22pt"
  main: "30pt"
  inset: "22pt"
---
# METATRON design system

## Overview

Operate mode. A native, restrained workspace with a precise geometric identity. The cube is an action layout and brand mark, not a substitute for labels or standard controls. The user approved graphite/petroleum and selectable presentations.

## Colors

Window, inset, label, secondary label and separator use NSColor semantic roles. Do not replace them with fixed web colors. The accent uses five ThemePreset pairs and a lightened dark-appearance variant. Errors and success retain native semantic colors. The brand artwork uses navy, ivory and muted teal.

## Typography

System SF text, native controls and SF Symbols. Workspace title 25pt semibold. Native headline/title3 for sections, caption for metadata. Monospaced digits belong to durations and measurements. Authorship is a quiet footer.

## Layout

Sidebar and workspace use NavigationSplitView. Main inset 30pt, section gap 22pt, input inset 22pt. File collections are bounded lazy lists. Compact and command access panels use a native list; the floating panel uses native segmented categories. The Metatron layout uses a transparent 480pt canvas, 166pt outer radius and 74pt action circles. Bubbles use a radial orbit of the same circular targets. Both share the classic borderless nonactivating panel and native drop surface; there is no title bar, toolbar, opaque canvas or rectangular panel shadow. Each circle has its own native masked material. The hub shows the selected file. Tab/Space cycle categories, Escape closes, and hit testing ignores the gaps.

## Elevation & Depth

Native window elevation only. Background geometry uses a thin static path with low opacity. It does not intercept clicks or drops. No decorative idle animation.

## Shapes

Inset panels use 12pt corners. The original mark consists of thirteen circles and the 78 connections between their centers. Small menu-bar and icon variants simplify the network for legibility. Action targets remain separated.

## Components

Six presentations share action dispatch and favorite destinations. Native buttons retain focus and keyboard behavior. Floating hosts accept the first mouse click and dismiss with Escape. A presentation token prevents an old drag-end callback from closing a newly opened panel. The palette accepts format identifiers such as md as well as visible names.

## Do's and Don'ts

Preserve originals during conversions, expose explicit moves, and keep author/donation links visible in Settings. Do not animate repeated keyboard operations. Do not force Metal when native CPU work measures faster. Do not convert native semantic surface colors into fixed light-only colors.
