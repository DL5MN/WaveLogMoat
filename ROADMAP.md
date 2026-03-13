# WaveLogMate Roadmap

> From QSO forwarder to goal-oriented WSJT-X companion for macOS — powered by Wavelog.

## Vision

WaveLogMate started as a simple bridge: receive QSOs from WSJT-X, forward them to Wavelog. The next step is to become a **goal-oriented hunting tool** — not another decode list (WSJT-X already does that well), but an app that answers: _"I'm chasing DXCC on 20m — what do I still need, and is any of it on the band right now?"_

JTAlert and JT-Bridge duplicate WSJT-X's decode list with color coding. WaveLogMate takes a different approach: **center the UI around award goals**, overlay live band activity on your progress, and make it one click to work a needed station.

The unique edge: **Wavelog is the single source of truth.** No local log databases to sync. Your award progress is always current, from any Mac.

---

## Phase 1 — QSO Forwarding (Done)

The current release. WSJT-X → WaveLogMate → Wavelog.

- Text protocol (Secondary UDP Server, port 2333) and binary protocol (port 2237)
- Real-time frequency, mode, DX call display (binary protocol)
- Heartbeat-based connection monitoring
- macOS notifications for logged/failed QSOs
- Keychain-secured API key
- Sparkle auto-updates, Homebrew cask, code-signed and notarized

---

## Phase 2 — Goal-Oriented Companion App

**Goal**: Transform WaveLogMate from a menu bar utility into a proper windowed macOS application centered around award hunting. The primary question is not "what's being decoded?" (WSJT-X shows that) but **"what do I still need, and is it on the band?"**

### 2a. Application Architecture

- **Single window**: One window, one app. Award progress dashboard with live "needed now" feed. The user shows it or hides it — no separate menu bar extra, no multi-window juggling. Standard macOS window with `WindowGroup`, `NavigationSplitView`, toolbar.
- **Settings**: Native `Settings` scene using `Form` with `.grouped` style and tab navigation.
- **Design language**: Apple HIG — SF Symbols, system colors, light/dark mode, vibrancy. No custom chrome.
- **SwiftUI patterns**: `@Observable`, `@Environment`, Swift concurrency (async/await, actors), `SwiftData` or in-memory store.
- **Minimum target**: macOS 14 (Sonoma) — `@Observable`, `SwiftData`, modern `Table`, `Inspector`.

### 2b. Award Goals

The user selects one or more active goals. Each goal tracks progress toward an award:

| Goal             | What it tracks                     | Source                          |
| ---------------- | ---------------------------------- | ------------------------------- |
| DXCC             | Entities worked/confirmed per band | `dxcc_entities` + QSO log       |
| CQ WAZ           | 40 CQ zones per band               | `COL_CQ_Z` in QSOs              |
| ITU Zones        | ITU zones per band                 | `COL_ITU_Z` in QSOs             |
| WAS              | 50 US states per band              | `COL_STATE` in QSOs             |
| WAC              | 6 continents per band              | `COL_CONT` / DXCC continent     |
| WPX              | Unique prefixes                    | Prefix extraction from callsign |
| Grid squares     | Maidenhead grids (4 or 6 char)     | `COL_GRIDSQUARE` in QSOs        |
| VUCC             | VHF/UHF grids                      | Grids on VHF+ bands             |
| Custom watchlist | Specific callsigns                 | User-defined list               |

Multiple goals can be active simultaneously. The app evaluates every decoded callsign against all active goals and surfaces the most interesting ones.

### 2c. Award Progress from Wavelog

**Problem**: Wavelog has no API for award progress. Internally, it computes everything on-the-fly from QSOs (controllers: `Awards.php`, models: `Dxcc.php`, `Was.php`, etc.). No precomputed tables.

**Strategy — two-tier approach**:

1. **Bulk sync on launch**: Export QSOs via `api/get_contacts_adif` (supports incremental fetch via `fetchfromid`). Build local award progress matrices in memory. Fields needed per QSO: `COL_DXCC`, `COL_CQ_Z`, `COL_ITU_Z`, `COL_STATE`, `COL_GRIDSQUARE`, `COL_BAND`, `COL_MODE`, `COL_QSL_RCVD`, `COL_LOTW_QSL_RCVD`, `COL_EQSL_QSL_RCVD`.

2. **Real-time per-decode**: Use `api/private_lookup` per decoded callsign to check worked/confirmed status. Cache aggressively (actor-based, keyed by callsign+band+mode). Invalidate after logging a QSO.

**Local data**: Ship a bundled `dxcc_entities` reference table (ADIF number → name, prefix, continent, CQ zone, ITU zone). Update periodically or on Wavelog sync.

**Upstream feature request**: Propose `api/awards/dxcc` (and similar) endpoints to Wavelog, mirroring the internal `get_dxcc_array()` model. Also: batch `private_lookup` for multiple callsigns in one request.

### 2d. Decode Processing

Parse WSJT-X binary protocol **type 2 (Decode)** messages:

| Field           | Type                      | Use                                         |
| --------------- | ------------------------- | ------------------------------------------- |
| Time            | QTime (ms since midnight) | Timestamp                                   |
| SNR             | qint32                    | Signal report                               |
| Delta time      | double                    | Time offset                                 |
| Delta frequency | quint32                   | Frequency offset (Hz)                       |
| Mode            | utf8                      | FT8, FT4, JT65, etc.                        |
| Message         | utf8                      | Decoded text → parse callsign, grid, CQ/QRZ |
| New             | bool                      | New decode vs replay                        |
| Low confidence  | bool                      | Flag uncertain decodes                      |

Extract callsigns and grids from `Message`. Handle FT8/FT4 formats:

- `CQ K1JT FN20` → CQ with grid
- `K1JT W1AW -05` → directed call
- `CQ DX K1JT FN20` → directed CQ

Also: **type 3 (Clear)** to reset, **type 7 (Replay)** on connect for history.

### 2e. WSJT-X Highlighting

**Key insight**: WSJT-X supports **type 13 (HighlightCallsign)** — we can push highlight colors directly into WSJT-X's Band Activity window. This means the user sees needed stations highlighted in WSJT-X itself, without switching apps.

```
Type 13 (HighlightCallsign) → WSJT-X
  Callsign: utf8
  Background: QColor (RGBA)
  Foreground: QColor (RGBA)
  Last only: bool (highlight last decode only, or all)
```

For every decoded callsign, evaluate against active goals and send highlight commands:

- **Red background**: New DXCC / new zone / new state (never worked)
- **Orange background**: Worked but unconfirmed
- **Yellow background**: New band slot (worked on other bands, not this one)
- No highlight: already worked+confirmed on this band

This is the **lowest friction possible** — the user doesn't even need to look at WaveLogMate's window. Needed stations light up right where they're already looking.

### 2f. Main Window Layout

The main window is NOT a decode list. It's a **goal dashboard with a live "needed now" feed**.

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ WaveLogMate                                                                      │
├──────────────────────────────────────────────────────────────────────────────────┤
│  Toolbar                                                                         │
│  ┌───────────┐  ┌────────────────────┐  ┌───────────────────────────────┐        │
│  │ ● WSJT-X  │  │ 14.074 MHz · FT8   │  │ DXCC ✓  WAZ ✓  WAS  Grids     │        │
│  │ Connected │  │                    │  │ (active goals, toggleable)    │        │
│  └───────────┘  └────────────────────┘  └───────────────────────────────┘        │
├────────────────────────────┬─────────────────────────────────────────────────────┤
│  Needed Now (live feed)    │  Award Progress                                     │
│                            │                                                     │
│  Stations decoded in the   │  ┌─ DXCC on 20m ───────────────────────────────┐    │
│  current cycle that match  │  │                                             │    │
│  your active goals:        │  │  Entity    160  80  40  30  20  15  10  SAT │    │
│                            │  │  ────────────────────────────────────────── │    │
│  ┌────────────────────┐    │  │  Germany    C   C   C   W   C   C   W   -   │    │
│  │ ● EA8/DJ5MN  IL18  │    │  │  Japan      W   C   W   -   C   -   -   -   │    │
│  │   Canary Is. · -12 │    │  │  Cocos-K.   -   -   -   -   ●   -   -   -   │    │
│  │   New DXCC!        │    │  │  Fiji       -   -   -   -   -   -   -   -   │    │
│  │   ▶ Reply to CQ    │    │  │  ...                                        │    │
│  └────────────────────┘    │  │                                             │    │
│  ┌────────────────────┐    │  │  Worked: 247/340 · Confirmed: 198/340       │    │
│  │ ● PY2XYZ    GG87   │    │  └─────────────────────────────────────────────┘    │
│  │   Brazil · -19     │    │                                                     │
│  │   Unconfirmed      │    │  ┌─ CQ WAZ on 20m ─────────────────────────────┐    │
│  │   ▶ Reply to CQ    │    │  │  Zones: ■■■■■□■■■■ ■■■□■■■■■■               │    │
│  └────────────────────┘    │  │         ■■■■■■■■■□ ■■□■■■■■■■               │    │
│  ┌────────────────────┐    │  │  Worked: 36/40 · Confirmed: 31/40           │    │
│  │ ● VK9DX    QH29    │    │  └─────────────────────────────────────────────┘    │
│  │   Christmas · -8   │    │                                                     │
│  │   Need on 20m      │    │  (scroll for more active goals)                     │
│  │   ▶ Reply to CQ    │    │                                                     │
│  └────────────────────┘    │                                                     │
│                            │                                                     │
│  (auto-scrolls, newest     │                                                     │
│   on top, clears each      │                                                     │
│   cycle)                   │                                                     │
├────────────────────────────┴─────────────────────────────────────────────────────┤
│  Status: 42 decoded · 3 needed · 1 new DXCC this session · Session: 4h 23m       │
└──────────────────────────────────────────────────────────────────────────────────┘


```

**Left panel — "Needed Now"**:

- Shows ONLY decoded stations that contribute to an active goal. Not a full decode list.
- Cards with: callsign, grid, entity/zone/state, SNR, why it's interesting (new DXCC / unconfirmed / new band slot).
- **"Reply to CQ" button** on each card → sends type 4 Reply to WSJT-X, initiating the QSO.
- Auto-refreshes each FT8/FT4 cycle. Old decodes fade or clear.
- Empty state: "All caught up — no needed stations on the band right now."

**Right panel — Award Progress**:

- Stacked cards for each active goal, showing the band/mode matrix.
- `C` = confirmed, `W` = worked, `-` = not worked, `●` = on band right now (live indicator!).
- Summary line: worked/total, confirmed/total.
- Click a goal card to expand to full detail view.
- For WAZ/ITU: compact zone grid (■ = worked, □ = needed).
- For grids: mini Maidenhead grid map (future).

**Toolbar**:

- Connection status + frequency/mode from WSJT-X.
- Active goal toggles (click to enable/disable goals).

**Status bar**:

- Cycle stats, session stats, time.

### 2g. Notifications & Alerts

macOS notifications for configurable conditions:

- New DXCC entity decoded (CQ)
- New zone/state for active goal
- Unconfirmed entity calling CQ
- Watchlist callsign decoded
- Own callsign decoded (someone calling you)

Optional: system sounds per alert category.

### 2h. Reply to CQ

Send commands to WSJT-X via UDP to initiate QSOs directly from WaveLogMate:

**Type 4 (Reply)**: Echo back the exact decode fields to start the QSO sequence.

```
Fields: Id, Time, SNR, Δt, Δf, Mode, Message, Low confidence, Modifiers
Modifiers: 0x02 = SHIFT (auto-sequence), 0x04 = CTRL/CMD
```

WSJT-X validates the message matches a CQ/QRZ decode, then begins the QSO. Only works for CQ/QRZ messages.

**Type 8 (HaltTx)**: Stop transmitting (emergency stop or cancel reply).

```
Fields: Id, Auto Tx Only (bool)
```

The "Reply to CQ" button on each Needed Now card sends Type 4 with `Modifiers=0x02` (SHIFT for auto-sequence). A "Stop TX" button appears while a QSO is in progress.

### Design Considerations

- **Binary protocol required**: Decode messages (type 2) and highlighting (type 13) need the binary protocol (port 2237). Phase 2 makes binary mode the default. Text protocol may be kept as a QSO-forwarding-only fallback.
- **Rate limiting**: Cache `private_lookup` results per callsign+band+mode. Actor-based concurrent cache. Invalidate on QSO log or band change. Typical FT8: 10-50 decodes every 15 seconds.
- **Bulk sync performance**: Initial ADIF export can be large (10k+ QSOs). Parse incrementally, show progress. Subsequent syncs are incremental (`fetchfromid`).
- **Highlighting latency**: Type 13 messages should be sent within 1-2 seconds of decode to be useful. Process decodes → cache lookup → highlight in pipeline. Cache hits are instant; misses go to Wavelog API.
- **Accessibility**: VoiceOver support. Colors supplemented with text labels and SF Symbols. Dynamic Type.

---

## Phase 3 — Enrichment & Polish

### 3a. Callsign Lookup

QRZ.com or HamQTH integration:

- Name, QTH, country, grid, license class.
- Detail popover when clicking a callsign in Needed Now panel.
- Auto-fetch for highlighted (new/needed) stations.

### 3b. Interactive Map

Built with **MapKit** (Apple Maps) — native, no API keys, dark mode support, built-in gestures.

The map lives in the Award Progress panel as a tab alongside the matrix view. Content adapts to the selected goal:

| Goal      | Map overlay                                                 |
| --------- | ----------------------------------------------------------- |
| DXCC      | Country/entity polygons, colored by worked/confirmed/needed |
| CQ WAZ    | 40 CQ zone boundaries                                       |
| ITU Zones | ITU zone boundaries                                         |
| WAS       | US state boundaries                                         |
| WAC       | Continent boundaries                                        |
| Grids     | Maidenhead grid overlay (2/4/6 char, zoom-dependent)        |

**Features**:

- **Color coding**: Green = confirmed, yellow = worked, red = needed, pulsing = on band right now.
- **Interactive**: Click a zone/entity/grid to see detail — what you've worked there, what's missing, QSO history.
- **Live activity**: Decoded stations with known grids appear as pins/annotations. Needed stations pulse or glow.
- **Zoom levels**: Grid map zooms from field (2-char) → square (4-char) → subsquare (6-char) as you zoom in.
- **Great circle path**: Optionally show bearing line from your QTH to selected station.

### 3c. Band Activity Map

Visual representation of the audio passband:

- Horizontal band showing decode positions by Δf.
- Color coded by goal relevance.
- Click to tune WSJT-X to that frequency (Type 15: Configure).

### 3d. Contest Mode

- Rate display (QSOs/hour).
- Multiplier tracking per contest rules.
- Running score.

### 3e. Statistics Dashboard

- QSOs today, this session, this month.
- New entities/zones/grids this session.
- Award progress trend over time.

### 3f. Community

- Customizable color schemes.
- Localization (German, at minimum).
- Submit to `homebrew/homebrew-cask`.

---

## API Dependencies

| Endpoint                | Phase    | Purpose                                     |
| ----------------------- | -------- | ------------------------------------------- |
| `api/qso`               | 1 (done) | Log QSOs                                    |
| `api/station_info`      | 1 (done) | Station profile picker                      |
| `api/private_lookup`    | 2        | Per-callsign worked/confirmed status        |
| `api/get_contacts_adif` | 2        | Bulk QSO export for local award computation |
| `api/statistics`        | 3        | Dashboard stats                             |

**Upstream feature requests for Wavelog**:

- `api/awards/dxcc` — DXCC band matrix (worked/confirmed per entity per band), mirroring internal `Dxcc::get_dxcc_array()`
- `api/awards/waz` / `was` / `itu` — Same for other awards
- Batch `private_lookup` — multiple callsigns in one request (critical for performance)
- Grid worked status in `private_lookup` response

## WSJT-X UDP Messages Used

| Type | Direction | Purpose                                       |
| ---- | --------- | --------------------------------------------- |
| 0    | In/Out    | Heartbeat (connection monitoring)             |
| 1    | Out       | Status (frequency, mode, DX call)             |
| 2    | Out       | Decode (callsign, SNR, Δf, message)           |
| 3    | In/Out    | Clear (reset decode list)                     |
| 4    | In        | Reply (initiate QSO from WaveLogMate)         |
| 5    | Out       | QSO Logged (forward to Wavelog)               |
| 7    | In        | Replay (request decode history on connect)    |
| 8    | In        | HaltTx (stop transmitting)                    |
| 9    | In        | FreeText (send custom message)                |
| 12   | Out       | Logged ADIF (QSO as ADIF string)              |
| 13   | In        | HighlightCallsign (color callsigns in WSJT-X) |

---

## Competitive Advantage

|                     | WaveLogMate            | JTAlert              | JT-Bridge                       |
| ------------------- | ---------------------- | -------------------- | ------------------------------- |
| Platform            | macOS (native SwiftUI) | Windows (.NET)       | macOS (unmaintained since 2021) |
| Core concept        | Goal-oriented hunting  | Decode list + alerts | Decode list + alerts            |
| Log source          | Wavelog (cloud)        | Local loggers        | Local loggers                   |
| Always in sync      | Yes (API)              | Only if logger open  | Only if logger open             |
| Multi-device        | Yes (same Wavelog)     | No                   | No                              |
| WSJT-X highlighting | Yes (type 13)          | No                   | No                              |
| One-click reply     | Yes (type 4)           | Yes                  | Yes                             |
| Award progress view | Built-in dashboard     | External (logger)    | External (logger)               |
| Auto-updates        | Sparkle                | Built-in             | Manual                          |

**Why this is different from JTAlert**: JTAlert adds color coding to a decode list — it answers "what is this station's status?" WaveLogMate answers "**what do I need, and is it available right now?**" The decode list stays in WSJT-X where it belongs. WaveLogMate is the strategic layer on top.
