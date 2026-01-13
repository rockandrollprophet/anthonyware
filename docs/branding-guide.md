# Anthonyware Branding Guide

Anthonyware is a personal engineering OS: black, white, and blood-red, with an anarchist "A" at its core.

---

## 1. Core Palette

- **Background:** `#000000` (pure black)
- **Primary Accent:** `#FF0000` (blood red)
- **Secondary Accent:** `#FFFFFF` (white)
- **Overlays:** black with alpha (0.3–0.6) for translucent panels

Usage:
- Waybar background: black with ~0.35 alpha
- Borders: `#FF0000`
- Active elements: red-on-black or black-on-red depending on focus

---

## 2. Fonts

Primary font stack:
- UI + terminal: `JetBrainsMono Nerd Font`
- Emoji: `Noto Color Emoji` / `noto-fonts-emoji`

Rules:
- No random font experiments in core configs
- All status bars and terminals use the same font for alignment

---

## 3. Iconography & Logo Concept

### Anarchist "A" Core

The logo is a stylized anarchist "A" that:
- Looks scraped, cut, or spray-painted
- Is slightly imperfect and aggressive
- Uses high contrast (white/red on black)

Concept directions:
- **Scraped metal:** a white "A" with jagged edges and slight roughness, as if carved into metal.
- **Spray paint:** a red "A" with slight overspray/glow, like stencil graffiti.

This "A" is the central mark used in:
- Plymouth (later)
- Lock screen tagline
- ASCII / MOTD
- Wallpapers
- Repo README

---

## 4. Motion & Effects

- Transparency mainly via Hyprland + Waybar: keep it subtle, functional.
- Blur: used sparingly for lock screen and maybe widget background.
- Animations: fast, snappy; no sluggish easing.

---

## 5. Tone

Anthonyware is:
- Direct, utilitarian, unapologetically technical
- Anti-bloat, anti-randomness
- Explicit and documented

Every UI piece should feel like it *belongs* in a hardened engineer's workstation, not a generic consumer desktop.