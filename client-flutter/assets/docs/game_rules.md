Star Cities is a simultaneous-move, turn-based strategy game for 2 to 6 players.

## Objective & Victory
A faction wins if they reach the objective score AND score higher than any other faction. If only one non-eliminated faction remains, that faction wins.

## The Board
- **Grid:** 9x9 squares.
- **Topology:** Torus (Left-to-right and Top-to-bottom wrapping).
- **Stars:** Roughly 6 stars are randomly placed. 
- **Occupancy:** Strictly one ship per square. Ships cannot move onto squares occupied by stars.

## Ships

### Ships Overview
| Name | Icon | Description |
| :--- | :---: | :--- |
| **Star City** | ![Star City](assets/ships/star-city.svg) ![Star City Anchored](assets/ships/star-city-anchored.svg) | The core of your faction. Anchor to new stars for score, support, and production. They can not move while they are anchored. They can be de-anchored if not supporting tethered ships. |
| **Neutrino** | ![Neutrino](assets/ships/neutrino.svg) | A stealthy scout. Cloaked and independent of tethers. |
| **Eclipse** | ![Eclipse](assets/ships/eclipse.svg) | A Starship featuring a laser cannon for long range bombardment. Bombardment disables the target ship movement that turn and has a probability of destroying the target. |
| **Parallax** | ![Parallax](assets/ships/parallax.svg) | Strong and mobile, an overall well-rounded starship. |

### Ship Attribute Comparison
| | Star City | Neutrino | Eclipse | Parallax |
| :--- | :---: | :---: | :---: | :---: |
| **Icon** | ![Star City](assets/ships/star-city.svg) ![Star City Anchored](assets/ships/star-city-anchored.svg) | ![Neutrino](assets/ships/neutrino.svg) | ![Eclipse](assets/ships/eclipse.svg) | ![Parallax](assets/ships/parallax.svg) |
| **Strength, Movement Speed, Vision Range** | 8.1.2 | 2.1.1 | 4.1.2 | 6.2.2 |
| **Tether Required** | No | No | Yes | Yes |
| **Special** | Anchor to new stars for score, support, and production | Cloak | Bombardment | |

## Scoring 
Score is used to determine victory and ship acquisition. 

Score is calculated as the number of distinct stars that your faction has a Star City anchored to. Anchoring two cities beside the same star does not increase score, the stars must be distinct. It is, however, ok if two cities of opposing factions are anchored to the same star, this will add to both of their scores.

## Tethers & Placement
- **Requirement:** Every Ship (except Neutrinos) must be **tethered** to a Star City.
- **Anchoring:** A Star City must be **anchored** beside a star to support tethers and allow placement of new ships.
- **Tether Range:** Eclipse and Parallax units must remain within a distance of 2 from their tethered Star City.
- **Capacity:** A Star City can support up to 5 tethered ships.
- **Loss of Tether:** If a Star City is destroyed or captured, all ships tethered to it are lost.
- **Re-tethering:** Ships can re-tether to a different anchored Star City if one is within range.
- **The Tray** The tray holds ships that have not been placed yet. There is a limit of five ships in the tray, if this is reached then no new ships can be received by acquisition.
- **Placement Flow:**
  1. Select a ship from the tray.
  2. Select an anchored friendly Star City to tether to.
  3. Select an available adjacent (distance 1) to that Star City.
  4. (Star City and Neutrino can be directly placed beside a star city because they do not require tether support)

## Player Actions
- **Simultaneous Turns:** All players plan moves simultaneously.
- **Planning:** Players can plan, undo, and reset actions until they finalize their turn.
- **Resolving the Turn** After all players have submitted their actions, the game server calculates the resulting events and the next turn state.

## Battle & Bombardment
- **Battle:** Occurs when multiple factions attempt to enter the same square.
- **Resolution:** A weighted probability determines the winner:
  - `Weight = Unit Strength + (0.5 * Strength of Support Units) + Bombardment Support`
  - **Support Units:** Allied ships in neighboring squares (distance 1).
  - **Bombardment Support** Allied ships bombarding the defending ship in the contested square.
- **Capturing Cities:** If a ship wins a battle against a Star City, the city is captured. The attacking ship remains in its original square.
- **Bombardment (Eclipse):** 
  - Range: 2 squares. Strength: 2.
  - Bombardments occur **before** movement in the same turn.
  - Effects: Prevents the target from moving that turn. Stacks with other bombardments (allied or not). Supports battles.
  - **Destruction:** If a Star City loses a battle due to bombardment, it is destroyed rather than captured.

## Turn Action Resolution Sequence

### Game Server Overview
The game server resolves player submitted actions to events and states `State1 + Actions1 -> Events1 + State2`. This is done in such a way that The order of submitted actions makes no difference. The game server resolves actions concurrently in stages. It is helpful to know these stages because they inform player strategy.

### Turn Resolution Stages (Generalization)
1. All Place, Anchor, Tether actions.
2. **Bombardments**
2. **Maneuvers:** All non-conflicting moves that can be made without battling.
3. **Battles**
4. **Advances** Victor moves and remaining moves that can be moved after battles.
5. **Ouctomes** Everything else.

Events of the previous turn can be reviewed in the 'Events' tab.

## Visibility & Stealth
- **Fog of War:** Players only squares within the vision range of their own ships.
- **Neutrino Cloak:** Neutrinos are invisible to other factions. They are forced to de-cloak if they are engaged in any battle on the previous turn, either directly or as support.

## Economy (Random Acquisition)
Each turn, a player has a probability of receiving a new ships. The number of roles they get is equal to their score. The probabilities per roll are:
- **Neutrino:** 25%
- **Eclipse:** 20%
- **Parallax:** 20%
- **Star City:** 10%
- **Nothing:** 25%

