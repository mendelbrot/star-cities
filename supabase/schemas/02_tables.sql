-- Enums
CREATE TYPE game_status AS ENUM ('WAITING', 'STARTING', 'PLANNING', 'RESOLVING', 'FINISHED');
CREATE TYPE faction AS ENUM ('RED', 'YELLOW', 'GREEN', 'CYAN', 'BLUE', 'MAGENTA');

-- User Profiles (Publicly visible user info)
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Games
CREATE TABLE games (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    status game_status NOT NULL DEFAULT 'WAITING',
    turn_number INTEGER NOT NULL DEFAULT 1,
    player_count INTEGER NOT NULL DEFAULT 4,
    stars JSONB, -- [{x, y}]
    game_parameters JSONB NOT NULL DEFAULT '{ "grid_size": 9, "star_count": 6, "star_count_to_win": 3, "max_ships_per_city": 5, "starting_ships": ["NEUTRINO", "NEUTRINO", "PARALLAX", "ECLIPSE"] }',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Players (Links users/bots to games and factions)
CREATE TABLE players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id), -- Nullable for bots
    is_bot BOOLEAN NOT NULL DEFAULT FALSE,
    bot_name TEXT, -- Friendly name for the bot (e.g., 'Easy AI')
    faction faction NOT NULL,
    home_star JSONB, -- {x, y}
    is_ready BOOLEAN NOT NULL DEFAULT FALSE,
    is_eliminated BOOLEAN NOT NULL DEFAULT FALSE,
    eliminated_on_turn INTEGER,
    is_winner BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Ensure a player is either a user or a bot
    CONSTRAINT player_identity CHECK (
        (is_bot = FALSE AND user_id IS NOT NULL) OR 
        (is_bot = TRUE AND user_id IS NULL)
    ),
    
    -- Faction must be unique within a game
    UNIQUE(game_id, faction)
);

-- Unique index for human players (prevents a user joining twice)
CREATE UNIQUE INDEX idx_unique_human_player_per_game 
ON players (game_id, user_id) 
WHERE user_id IS NOT NULL;

-- Add winner reference after players table exists 
ALTER TABLE games ADD COLUMN winner UUID REFERENCES players(id);

-- Turn States (Snapshots of the board at the START of a turn)
CREATE TABLE turn_states (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    turn_number INTEGER NOT NULL,
    state JSONB NOT NULL DEFAULT '[]', -- List of Piece objects
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(game_id, turn_number)
);

-- Turn Planned Actions (Intents submitted by players)
CREATE TABLE turn_planned_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    turn_number INTEGER NOT NULL,
    actions JSONB NOT NULL DEFAULT '[]',
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Each player can only have one set of planned actions per turn.
    UNIQUE(game_id, player_id, turn_number)
);

-- Turn Events (Resolved outcomes for a turn)
CREATE TABLE turn_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    turn_number INTEGER NOT NULL,
    events JSONB NOT NULL DEFAULT '[]', -- List of Event objects
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(game_id, turn_number)
);
