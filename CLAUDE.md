# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Beerkeeper is an event management application for the mitaka.rb Ruby community. It's built with Rails 8.0.2 and uses modern Rails patterns including ViewComponents and Turbo.

## Key Commands

### Development Setup
```bash
# Local development
bin/setup
bin/dev  # Starts Rails server and CSS watcher with foreman

# Docker development
docker compose build
docker compose run --rm web bin/setup
docker compose up
```

### Testing
```bash
# Run all tests
bundle exec rspec

# Run specific test
bundle exec rspec spec/path/to/test_spec.rb
bundle exec rspec spec/path/to/test_spec.rb:line_number

# Type check app/models (sig/ holds handwritten RBS, sig/rbs_rails/ is generated)
bundle exec rbs collection install
bundle exec steep check
bin/rails rbs_rails:all  # regenerate after changing models, associations or routes

# Run tests in Docker
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec
```

### Database
```bash
bin/rails db:migrate
bin/rails db:seed
bin/rails db:reset  # Drop, create, migrate, seed
```

### Console & Development Tools
```bash
bin/rails console
bin/rails c  # shorthand

# CSS/Asset building
bin/rails dartsass:build
```

## Architecture Overview

### Core Models & Relationships
- **User**: Event participants and organizers (has_secure_password)
  - `has_many :organizing_events` (as organizer)
  - `has_many :participations`
  - `has_many :participating_events` (through participations)
  
- **Event**: Community events
  - `belongs_to :organizer` (User)
  - `has_many :participations`
  - `has_many :participants` (through participations)

- **Participation**: Join table for User-Event many-to-many relationship

### Frontend Architecture
- **ViewComponents** (`app/components/`) for reusable UI components
- **Bootstrap 5.3.5** for styling
- **Turbo Rails** for SPA-like interactions without full page reloads
- **Stimulus** for JavaScript behavior
- **Importmap Rails** for JavaScript module management (no webpack/bundler)

### Testing Strategy
The codebase follows Test-Driven Development (TDD) principles:

1. **Model Specs** (`spec/models/`): Unit tests for business logic
2. **Request Specs** (`spec/requests/`): API/controller integration tests
3. **System Specs** (`spec/system/`): Full E2E tests with Capybara
4. **Component Specs** (`spec/components/`): ViewComponent unit tests

Test utilities:
- **FactoryBot** for test data generation (`spec/factories/`)
- **Capybara** with Selenium for browser testing
- **RSpec Rails** as the testing framework

### Development Workflow Notes

1. **CSS Compilation**: The project uses DartSass Rails. CSS is automatically compiled during tests and can be manually built with `bin/rails dartsass:build`.

2. **Database**: SQLite everywhere. Production is `storage/production.sqlite3` on a Fly.io volume, migrated by `db:prepare` in `bin/docker-entrypoint` when the machine boots.

3. **Environment Setup**: The `bin/setup` script handles all initial setup including dependencies, database creation, and migrations.

4. **Docker Support**: Full Docker development environment is available. All commands can be run either locally or in Docker containers.

5. **CI/CD**: RunSpecs (rspec + rubocop + steep) runs on PRs and on main. Fly Deploy runs only after RunSpecs succeeds on main. Dependabot is configured for automated dependency updates.


## Key Directories

- `app/components/`: ViewComponent-based UI components
- `app/controllers/`: Standard Rails controllers
- `app/models/`: ActiveRecord models with business logic
- `app/views/`: ERB templates organized by controller
- `spec/`: All test files organized by type
- `config/`: Rails configuration including routes, database, and environments
- `db/`: Database migrations and schema
## Fork and release state

This is `dlwr/beerkeeper`, a fork of `mitakarb/beerkeeper` developed independently. Do not open PRs, issues or comments on upstream, and do not reference upstream issues with links (write them in backticks) so nothing shows up in upstream timelines.

**Release state: pre-release** (no real users yet). Only the owner edits this line.

- Pre-release: migrations, authorization changes and deploys may be merged without asking, once CI is green and `beerkeeper-invariants-reviewer` has no blocking findings.
- Post-release: production deploys, migrations, and secret changes need the owner's approval. Stop at the PR for any change that drops or rewrites data.

The north star is the first milestone with open issues, in the order `discord` → `usability` (the `release` milestone is done). The autonomous loop is described in `.claude/skills/jisou/SKILL.md`.
