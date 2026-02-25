-- Enums
CREATE TYPE game_status AS ENUM ('WAITING', 'STARTING', 'PLANNING', 'RESOLVING', 'FINISHED');
CREATE TYPE faction AS ENUM ('BLUE', 'RED', 'PURPLE', 'GREEN');

-- User Profiles (Publicly visible user info)
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    profile_icon TEXT NOT NULL DEFAULT 'default_icon',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Games
CREATE TABLE games (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    status game_status NOT NULL DEFAULT 'WAITING',
    turn_number INTEGER NOT NULL DEFAULT 1,
    player_count INTEGER NOT NULL DEFAULT 4,
    stars JSONB -- [{x, y}]
    game_parameters JSONB NOT NULL DEFAULT '{ "grid_size": 9, "star_count_to_win": 3, "max_ships_per_city": 5 }',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Players (Links users to games and factions)
CREATE TABLE players (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    faction faction NOT NULL,
    home_star JSONB, -- {x, y}
    is_ready BOOLEAN NOT NULL DEFAULT FALSE,
    is_eliminated BOOLEAN NOT NULL DEFAULT FALSE,
    eliminated_on_turn INTEGER,
    is_winner BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE(game_id, user_id),
    UNIQUE(game_id, faction)
);

-- Add winner reference after players table exists 
ALTER TABLE games ADD COLUMN winner UUID REFERENCES players(id);

-- Turn States (Snapshots of the board at the START of a turn)
CREATE TABLE turn_states (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    turn_number INTEGER NOT NULL,
    state JSONB NOT NULL DEFAULT '[]', -- List of Piece objects
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(game_id, turn_number)
);

-- Turn Planned Actions (Intents submitted by players)
CREATE TABLE turn_planned_actions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    turn_number INTEGER NOT NULL,
    actions JSONB NOT NULL DEFAULT '[]',
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    -- We allow multiple rows per player/turn to record history. 
    -- The server will pick the one with the latest 'submitted_at'.
);

-- Turn Events (Resolved outcomes for a turn)
CREATE TABLE turn_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    turn_number INTEGER NOT NULL,
    events JSONB NOT NULL DEFAULT '[]', -- List of Event objects
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(game_id, turn_number)
);
