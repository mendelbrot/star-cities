## Star Cities Project Overview

Star Cities is a cross-platform turn based simultaneous move strategy game. Think space chess.

- **Frontend:** Flutter (`client-flutter/`)
- **Database Backend:** Supabase/PostgreSQL (`supabase/schemas/`)
- **Game Server Backend** (`supabase/functions`) Deno Supabase edge functions
- **Knowledge Base:** ('notes-star-cities/`)

### Flutter Frontend Guidelines (`client-flutter/`)
- NEVER run the app to verify changes (the user handles this). 
- Check for compile errors after Flutter coding tasks by running `npm run flutter:analyze`.

### Supabase/PostgreSQL Backend Guidelines (`supabase/schemas`)
- NEVER create migration files. We use declarative schema. Edit the schemas in `supabase/schemas/` directly.
- NEVER generate migrations after editing the schemas; the user will handle migrations.
- NEVER run `supabase` CLI commands; the user will handle migration, verification, and deployment.

### Supabase Functions Backend Guidelines
- Check for errors with deno check and deno lint, on all edited typescript files.

## Knowledge Management (`notes-star-cities/`)

- **`notes-star-cities/docs/`**: **Up-to-date Documentation.** 
- **`notes-star-cities/knowledge/`**: Deep-dives into specific concepts and patterns.
- **`notes-star-cities/assets/`**: Visual assets, including:
    - `diagrams/`: Mermaid source files (`.mmd`).
    - `images/`: Generated SVG diagrams (via `npm run mermaid`) and other images.
- **`notes-star-cities/dev-logs/`**: These files are for the developer and the agent to write about current thoughts and tasks. 

### Visual Documentation (Mermaid)
- **Workflow:** Store Mermaid source files in `notes-star-cities/assets/diagrams/`.
- **Generation:** Run `npm run mermaid` to generate SVG images in `notes-star-cities/assets/images/`.
- **Usage:** Use these diagrams in stable documentation (`notes-star-cities/docs/`) to illustrate system architecture and data flows.

## How to use agent logs (`notes-star-cities/dev-logs/`)
You append your logs to the the `Agent Logs` section (don't edit previous writing). The npm script for creating a log is just for making a an empty template. To add to an existing log file, you need to open the file and write to it manually. The log filename has the date followed by a two digit number that's incremented if I decide to start a new log on the same. (I will sometimes do this if the first log gets two full or if I decide to change focus to a different area of the code)

Currently I usually favor small tasks over big plans. Generally, add a sentence in your log for each task that you do, just as you would tell me what you did in the CLI. See your previous logs for writing style reference. If you forget and I say "log this" then just copy what you told me in our conversation into the log.

Think of these logs as a kind of memory. Read the most recent log files to get up to speed on the project.


## Agent's initial instructions
As the first thing that you do, please get up to speed on the project:
  - read the latest two dev log files in `notes-star-cities/dev-logs/`
  - learn the game rules: `notes-star-cities/docs/game_rules.md`
  - learn the data models and detailed game mechanics: `notes-star-cities/docs/data_models_and_game_logic.md`

