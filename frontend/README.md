# JW Stairs Frontend

Vue.js 3 web UI for the JW Stairs LED stair controller. Provides a browser-based interface for controlling LED animations, managing scenes, and configuring lighting options.

## Tech Stack

| Technology | Purpose |
|------------|---------|
| [Vue.js 3](https://vuejs.org/) | UI framework (Composition API) |
| [Vite](https://vite.dev/) | Build tool and dev server |
| [Pinia](https://pinia.vuejs.org/) | State management |
| [Vue Router](https://router.vuejs.org/) | Client-side routing |
| [Playwright](https://playwright.dev/) | End-to-end testing |

## Project Structure

```
src/
├── App.vue            # Root component with header, nav, and router view
├── main.js            # Application entry point
├── assets/            # Static assets and global styles
├── router/            # Vue Router configuration (/, /scenes, /scenes/:id)
├── services/          # API service layer for backend communication
├── stores/            # Pinia stores (shows, scenes)
└── views/             # Page components
    ├── AnimationsView.vue    # Animation controls and show selection
    ├── ScenesView.vue        # Scene list and CRUD management
    └── SceneDetailView.vue   # Individual scene with frame details
```

## Views

### AnimationsView (`/`)

Main control panel for LED animations. Includes brightness slider, primary/secondary color pickers, color order selector (RGB, RBG, GRB, GBR, BRG, BGR), repeat toggle, and a turn-off button. Displays available animation shows as a card grid.

![Animations View](https://github.com/user-attachments/assets/1e025735-c45d-4efa-abfc-9b768919261d)

### ScenesView (`/scenes`)

Lists saved scenes with options to create, edit, play, and delete. The create form allows naming new scenes via inline input.

![Scenes View](https://github.com/user-attachments/assets/48585bd9-6f7c-455e-ade9-d1c46dfbaaea)

### SceneDetailView (`/scenes/:id`)

Displays scene metadata (ID, name, frame count) and a list of frames with LED color previews.

![Scene Detail View](https://github.com/user-attachments/assets/2b759445-8643-4afd-ab29-6550e96e2cc3)

## Getting Started

### Prerequisites

- Node.js 20+ (22+ recommended)

### Development

```bash
npm install
npm run dev
```

The dev server starts at `http://localhost:5173`.

### Production Build

```bash
npm run build
```

Built files are output to the `dist/` directory.

## E2E Testing

End-to-end tests use [Playwright](https://playwright.dev/) with Chromium.

```bash
# Install Playwright browsers (first time only)
npx playwright install

# Run all e2e tests
npm run test:e2e
```

Test files are located in the `e2e/` directory. The Playwright configuration (`playwright.config.js`) automatically starts the Vite dev server on port 5173 before running tests.

## API Integration

The Vite dev server proxies API requests to the backend at `http://localhost:5001`:

| Route | Backend Target |
|-------|---------------|
| `/shows` | `http://localhost:5001/shows` |
| `/scenes` | `http://localhost:5001/scenes` |
| `/animation` | `http://localhost:5001/animation` |

The `/scenes` proxy includes a bypass rule so that browser navigation requests (accepting `text/html`) are handled by Vue Router instead of being proxied.

To override the API base URL, set the `VITE_API_BASE` environment variable.
