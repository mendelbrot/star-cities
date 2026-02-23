-- Enums
CREATE TYPE game_status AS ENUM ('WAITING', 'PLANNING', 'RESOLVING', 'FINISHED');
CREATE TYPE faction AS ENUM ('BLUE', 'RED', 'YELLOW', 'GREEN');

-- Games
CREATE TABLE games (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    status game_status NOT NULL DEFAULT 'WAITING',
    current_turn_number INTEGER NOT NULL DEFAULT 1,
    grid_size INTEGER NOT NULL DEFAULT 9,
    stars JSONB NOT NULL DEFAULT '[]', -- List of {x, y}
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
    UNIQUE(game_id, user_id),
    UNIQUE(game_id, faction)
);

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
