# Star Cities - Game Rules

## Overview
Star Cities is a simultaneous-move, turn-based strategy game for 2 to 6 players.

## Objective & Victory
A faction wins if it is anchored to the objective number of distinct stars AND has more stars than any other faction. If only one non-eliminated faction remains, that faction wins.

## The Board
- **Grid:** 9x9 squares.
- **Topology:** Torus (Left-to-right and Top-to-bottom wrapping).
- **Stars:** Roughly 6 stars are randomly placed. 
- **Occupancy:** Strictly one ship per square. Ships cannot move onto squares occupied by stars.

## Ships & Attributes

### Ships Overview
| Name | Icon | Description |
| :--- | :---: | :--- |
| **Star City** | ![Star City](assets/ships/star-city.svg) ![Star City Anchored](assets/ships/star-city-anchored.svg) | The core of your faction. Supports tethers and piece placement when anchored to a star. |
| **Neutrino** | ![Neutrino](assets/ships/neutrino.svg) | A stealthy scout. Cloaked and independent of tethers. |
| **Eclipse** | ![Eclipse](assets/ships/eclipse.svg) | A long-range fire support ship. Equipped with a laser cannon. |
| **Parallax** | ![Parallax](assets/ships/parallax.svg) | A high-speed interceptor and mobile combatant. |

### Ship Attribute Comparison
| | Star City | Neutrino | Eclipse | Parallax |
| :--- | :---: | :---: | :---: | :---: |
| **Icon** | ![Star City](assets/ships/star-city.svg) ![Star City Anchored](assets/ships/star-city-anchored.svg) | ![Neutrino](assets/ships/neutrino.svg) | ![Eclipse](assets/ships/eclipse.svg) | ![Parallax](assets/ships/parallax.svg) |
| **Strength, Movement Speed, Vision Range** | 8.1.2 | 2.1.1 | 4.1.2 | 6.2.2 |
| **Tether Required** | No | No | Yes | Yes |
| **Special** | Anchor to Star | Cloaked | Laser Cannon | High Mobility |

## Tethers & Placement
- **Requirement:** Every Ship (except Neutrinos) must be tethered to a Star City.
- **Anchoring:** A Star City must be **anchored** beside a star to support tethers and allow placement of new ships.
- **Tether Range:** Eclipse and Parallax units must remain within a distance of 2 from their tethered Star City.
- **Capacity:** A Star City can support up to 5 tethered ships.
- **Loss of Tether:** If a Star City is destroyed or captured, all ships tethered to it are also lost.
- **Re-tethering:** Ships can re-tether to a different anchored Star City if one is within range.
- **Placement Flow:**
  1. Select a ship from the acquired tray.
  2. Select an anchored friendly Star City to tether to.
  3. Select an empty square adjacent (distance 1) to that Star City.

## Movement & Actions
- **Simultaneous Turns:** All players plan moves simultaneously.
- **Planning:** Players can plan, undo, and reset moves until they finalize their turn.
- **Star City Mobility:** An anchored Star City cannot move. It can only de-anchor to move if it has **no** ships currently tethered to it.

## Combat & Bombardment
- **Battle:** Occurs when multiple factions attempt to enter the same square.
- **Resolution:** A weighted probability determines the winner:
  - `Weight = Unit Strength + (0.5 * Strength of Support Units)`
  - **Support Units:** Friendly units in neighboring squares (distance 1).
- **Capturing Cities:** If a ship wins a battle against a Star City, the city is captured. The attacking ship remains in its original square.
- **Bombardment (Eclipse):** 
  - Range: 2 squares. Strength: 2.
  - Bombardments occur **before** movement in the same turn.
  - Effects: Stacks with other bombardments.
  - **Destruction:** If a Star City loses a battle due to bombardment, it is destroyed rather than captured.

## Visibility & Stealth
- **Fog of War:** Players only see enemy units within the vision range of their own ships.
- **Neutrino Cloak:** Neutrinos are invisible unless they:
  - Won a battle on the previous turn.
  - Are collided with directly.
  - Act as support in a battle visible to the opponent.

## Economy (Random Acquisition)
Each turn, a player has a probability of receiving a new ship in their tray:
- **Neutrino:** 25%
- **Eclipse:** 20%
- **Parallax:** 20%
- **Star City:** 10%
- **Nothing:** 25%
