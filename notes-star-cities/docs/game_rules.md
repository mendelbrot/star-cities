# Star Cities - Game Rules

## Overview
Star Cities is a simultaneous-move, turn-based strategy game played on a 9x9 grid with a topological torus structure (the edges wrap around). The game supports 2 to 4 players.

## Objective & Victory
A faction wins if it is anchored to 3 or more distinct stars AND has more stars than any other faction.
 If only one non-eliminated faction remains, that faction wins.

## The Board
- **Grid:** 9x9 squares.
- **Topology:** Torus (Left-to-right and Top-to-bottom wrapping).
- **Stars:** Roughly 6 stars are randomly placed. 
- **Occupancy:** Strictly one piece per square. Pieces cannot move onto squares occupied by stars.

## Pieces & Attributes

| Type | Strength | Movement | Vision | Tether Required | Visual | Special |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **Star City** | 8 | 1 | 2 | No | City Icon | Supports tethers/placement when anchored. |
| **Neutrino** | 2 | 1 | 1 | No | Diamond | Cloaked; only visible if it won a battle last turn. |
| **Eclipse** | 4 | 1 | 2 | Yes | Circle | Laser Cannon: Range 2, Strength 2. Stuns target. |
| **Parallax** | 6 | 2 | 2 | Yes | Triangle | High mobility. |

## Tethers & Placement
- **Requirement:** Every Ship (except Neutrinos) and Star City must be tethered to a Star City.
- **Anchoring:** A Star City must be **anchored** beside a star to support tethers and allow placement of new pieces.
- **Tether Range:** Eclipse and Parallax units must remain within a distance of 2 from their tethered Star City.
- **Capacity:** A Star City can support up to 6 tethered pieces.
- **Loss of Tether:** If a Star City is destroyed or captured, all pieces tethered to it are also lost.
- **Re-tethering:** Ships can re-tether to a different anchored Star City if one is within range.
- **Placement Flow:**
  1. Select a piece from the acquired tray.
  2. Select an anchored friendly Star City to tether to.
  3. Select an empty square adjacent (distance 1) to that Star City.

## Movement & Actions
- **Simultaneous Turns:** All players plan moves simultaneously.
- **Planning:** Players can plan, undo, and reset moves until they finalize their turn.
- **Star City Mobility:** An anchored Star City cannot move. It can only de-anchor to move if it has **no** ships currently tethered to it.
- **Stun:** A piece hit by a bombardment is stunned and cannot move during the following turn.

## Combat & Bombardment
- **Battle:** Occurs when multiple factions attempt to enter the same square.
- **Resolution:** A weighted probability determines the winner:
  - `Weight = Unit Strength + (0.5 * Strength of Support Units)`
  - **Support Units:** Friendly units in neighboring squares (distance 1).
- **Capturing Cities:** If a ship wins a battle against a Star City, the city is captured. The attacking ship remains in its original square.
- **Bombardment (Eclipse):** 
  - Range: 2 squares. Strength: 2.
  - Bombardments occur **before** movement.
  - Effects: Stacks with other bombardments; stuns the target.
  - **Destruction:** If a Star City loses a battle due to bombardment, it is destroyed rather than captured.

## Visibility & Stealth
- **Fog of War:** Players only see enemy units within the vision range of their own pieces.
- **Neutrino Cloak:** Neutrinos are invisible unless they:
  - Won a battle on the previous turn.
  - Are collided with directly.
  - Act as support in a battle visible to the opponent.

## Economy (Random Acquisition)
Each turn, a player has a probability of receiving a new piece in their tray:
- **Neutrino:** 25%
- **Eclipse:** 20%
- **Parallax:** 20%
- **Star City:** 10%
- **Nothing:** 25%
