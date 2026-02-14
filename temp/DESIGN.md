---
name: Kaminari Browser
colors:
  surface: '#15130b'
  surface-dim: '#15130b'
  surface-bright: '#3c392f'
  surface-container-lowest: '#100e07'
  surface-container-low: '#1e1c13'
  surface-container: '#222017'
  surface-container-high: '#2c2a21'
  surface-container-highest: '#37352b'
  on-surface: '#e8e2d4'
  on-surface-variant: '#cdc6af'
  inverse-surface: '#e8e2d4'
  inverse-on-surface: '#333027'
  outline: '#96917b'
  outline-variant: '#4b4735'
  surface-tint: '#ddc73f'
  primary: '#ffffff'
  on-primary: '#383000'
  primary-container: '#fbe359'
  on-primary-container: '#726400'
  inverse-primary: '#6c5e00'
  secondary: '#d5c789'
  on-secondary: '#383002'
  secondary-container: '#524918'
  on-secondary-container: '#c6b97c'
  tertiary: '#ffffff'
  on-tertiary: '#003737'
  tertiary-container: '#57f8f9'
  on-tertiary-container: '#007071'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#fbe359'
  primary-fixed-dim: '#ddc73f'
  on-primary-fixed: '#211c00'
  on-primary-fixed-variant: '#514700'
  secondary-fixed: '#f1e3a3'
  secondary-fixed-dim: '#d5c789'
  on-secondary-fixed: '#211b00'
  on-secondary-fixed-variant: '#504716'
  tertiary-fixed: '#57f8f9'
  tertiary-fixed-dim: '#29dcdd'
  on-tertiary-fixed: '#002020'
  on-tertiary-fixed-variant: '#004f50'
  background: '#15130b'
  on-background: '#e8e2d4'
  surface-variant: '#37352b'
typography:
  display-lg:
    fontFamily: Space Grotesk
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg-jp:
    fontFamily: Noto Sans JP
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-sm-mono:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base_unit: 4px
  margin-mobile: 1.25rem
  gutter-mobile: 1rem
  stack-sm: 0.5rem
  stack-md: 1rem
  stack-lg: 2rem
---

## Brand & Style

The visual identity of the design system centers on the concept of "High-Voltage Learning." It targets a demographic of tech-savvy language learners who appreciate speed, efficiency, and a futuristic aesthetic. The brand personality is energetic, precise, and sophisticated.

The UI utilizes a mix of **Glassmorphism** and **High-Contrast Dark Mode**. It mimics the atmosphere of a Tokyo night—deep shadows punctuated by vibrant, electric neon light. The emotional response should be one of "focused energy"; the dark background reduces eye strain during long reading sessions, while the new **Electric Gold** accents direct the user's attention to critical learning moments, with cyan reserved for specialized tertiary highlights.

## Colors

The palette is anchored by **Deep Midnight Charcoal** to provide an infinite depth for the browser interface. The primary kinetic energy now comes from **Electric Gold (#AA9601)**, which is reserved for primary calls-to-action, active states, and essential learning metrics.

**Muted Bronze Grays** act as the structural framework, separating content without creating visual noise. **Cyber Cyan (#5CFCFD)** has been moved to a tertiary role, used for specialized "mastery" status and high-priority progress milestones. Functional colors for "Success" and "Error" are saturated and lean towards neon hues to maintain the high-tech aesthetic. Gradients should be used sparingly, primarily as subtle "electric" glows behind high-priority cards or active progress bars.

## Typography

This design system employs a tri-font strategy to balance technical precision with cultural elegance. 

1.  **Space Grotesk** is used for headlines to provide a futuristic, geometric edge. 
2.  **Inter** handles the heavy lifting of UI labels and English body text for maximum legibility.
3.  **Noto Sans JP** (or a similar modern Gothic) is specified for Kanji/Kana to ensure clarity at all sizes, particularly for complex strokes.
4.  **JetBrains Mono** is utilized for metadata and "system" information (like word counts or dictionary codes) to reinforce the "browser as a tool" feel.

Typography for Japanese characters should generally be 10-15% larger than the accompanying English text to maintain perceived optical balance.

## Layout & Spacing

The layout philosophy follows a **Dynamic Grid** model tailored for mobile consumption. We utilize a 4-column grid for mobile with 20px (1.25rem) side margins. The spacing rhythm is strictly based on a 4px baseline, ensuring that all components—from small tags to large media cards—align to a consistent vertical beat.

Navigation is handled via a bottom "Command Bar" and tag-based chips for filtering content. In Japanese text displays, line-height is increased (1.6x to 1.8x) to prevent "clipping" of complex Kanji and to allow for Furigana (reading aids) to be placed above the text without crowding the line above.

## Elevation & Depth

Depth is communicated through **Glassmorphism** rather than traditional drop shadows. Surfaces closer to the user are lighter in tone and feature a `backdrop-filter: blur(12px)`. 

To simulate the "Lightning" theme, active elements or cards with high-priority metrics feature a subtle inner glow or a 1px "electric" border using a low-opacity version of the Primary Gold. Backgrounds use a "Tonal Layering" approach:
- **Level 0:** Background
- **Level 1:** Content Cards
- **Level 2:** Modals/Overlays (with 80% opacity and blur)

Shadows, when used, are colored (e.g., a faint gold glow) rather than black, creating the illusion of a light-emitting interface.

## Shapes

The design system uses a **Rounded (Level 2)** shape language. This softens the aggressive high-contrast color palette, making the app feel more approachable as an educational tool while maintaining its modern edge.

- Standard buttons and input fields use a `0.5rem` radius.
- Media cards and learning modules use a `1.5rem` (rounded-xl) radius to create a distinct containerized feel.
- Tags and pill-based navigation use a fully rounded (stadium) shape to differentiate them from functional buttons.

## Components

### Buttons & Inputs
Primary buttons are solid **Electric Gold** with dark text for maximum contrast. Secondary buttons use a ghost style (muted bronze border) with a subtle hover glow. Input fields are dark with a 1px bottom border that "charges" (turns gold) when focused.

### Sleek Progress Bars
Learning metrics are displayed using slim, 4px-high progress bars. The "unfilled" portion is a deep bronze/slate, while the "filled" portion is a vibrant gold with a soft outer glow. Mastery metrics may use the cyan accent.

### Tag-Based Navigation
Tags are used for grammar categories (e.g., N5, Verb, Slang). They feature a semi-transparent bronze background and monochromatic text, turning gold only when selected.

### Media Cards
Cards used for articles or videos use a glassmorphic footer for titles. The images should have a slight dark overlay to ensure that the gold UI elements "pop" when overlaid.

### Kanji Detail Cards
Specialized cards for Kanji study feature a large display area for the character, a stroke-order animation toggle, and a "voltage meter" using the cyan tertiary color to represent the user's mastery level.