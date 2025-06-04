# Epos Raid Tools

**Epos Raid Tools** is a World of Warcraft addon designed to help raid leaders and officers track guild members’ custom currencies (e.g., “crests”) and roster status. It automatically scans your guild roster, fetches per-player currency data via AceComm, and presents everything in a clean, scrollable UI—complete with role-based filters, blacklists, and on-demand data requests.

---

## Table of Contents

1. [Features](#features)
2. [Installation](#installation)
3. [Usage](#usage)
   - [Guild Roster](#guild-roster)
   - [Crests Tab](#crests-tab)
   - [Requesting & Receiving Data](#requesting--receiving-data)
4. [Configuration & Saved Variables](#configuration--saved-variables)
5. [File Structure](#file-structure)
6. [License](#license)

---

## Features

- **Automatic Guild Roster Scanning**
  - On login or whenever the guild roster updates, the addon builds a list of max‐level guild members (via `fetchGuild`).
  - Stores each member’s name, rank, level, and class in `EposRT.GuildRoster`.

- **Live Currency Data Fetching**
  - Uses AceComm-3.0 to listen for `“EPOSDATABASE”` messages.
  - When a trusted sender pushes a compressed/serialized payload, the addon decodes it and updates `EposRT.PlayerDatabase` with per-player currency info (quantity, total earned, cap, timestamp, etc.).

- **Role-Based Filters & Blacklists**
  - Only tracks guild members whose rank is enabled in Roles Management and who are not blacklisted.
  - Easily add or remove players from the blacklist to exclude them from all tabs.

- **Clean, Scrollable UI**
  - Two main tabs: **Roster** (status tracking) and **Crests** (currency tracking).
  - On-demand “Request Data” buttons to fetch the latest information from peers running the addon.

- **Custom Currency Tracking**
  - Default currency ID: `3114` (crests), but you can add/remove any other currency IDs in the Crests Options dialog.

---

## Installation

1. **Download or Clone** this repository into your World of Warcraft AddOns folder.
   - Typical path:
     ```
     World of Warcraft/_retail_/Interface/AddOns/EposRaidTools/
     ```
2. **Log in to WoW** and ensure **Epos Raid Tools** appears in your AddOns list on the character select screen.
3. **Enable** the addon, then log in to any character to start using it.

---

## Usage

### Guild Roster

1. Open the **Epos Raid Tools** main window (e.g., via minimap icon or slash command).
2. Select the **Roster** tab.
3. The addon automatically scans your guild roster and lists every max‐level member whose rank is enabled under Roles Management and who is not blacklisted.
4. Columns in the **Roster** tab:
   - **Name** (player name and realm)
   - **Rank** (guild rank)
   - **Status** (whether we’ve received currency data for that player)
   - **Updated** (timestamp of last data received via AceComm)

5. **Roles Management**:
   - Click **Roster Options** (top-left) to open the Roles Management panel.
   - Toggle which guild ranks to include (e.g., Guildlead, Officer, Raider).
   - Open the Blacklist editor to exclude specific players by full name.

6. **Request Data**:
   - Click **Request Data** (top-right) to send an AceComm request.
   - Other players running Epos Raid Tools will respond with their current currency payload.

### Crests Tab

1. Switch to the **Crests** tab to view currency info for every player in the filtered roster.
2. Columns in the **Crests** tab:
   - **Name** (player name and realm)
   - **Available** (current amount of tracked currency)
   - **Obtainable** (amount they can still earn this week, if applicable)
   - **Used** (amount already spent or capped)
   - **Total Earned** (lifetime total of that currency)
   - **Updated** (timestamp of last data received)

3. **Crests Options**:
   - Click **Crests Options** (top-left) to add or remove currency IDs you want to fetch (default is `3114`).
   - Any valid WoW currency ID can be tracked.

4. **Request Data**:
   - Click **Request Data** (top-right) to refresh every player’s currency info via AceComm.

---

## Requesting & Receiving Data

- Whenever you click **Request Data** (in either the Roster or Crests tab), Epos Raid Tools broadcasts an AceComm message on channel `“EPOSDATABASE”`.
- Any other player running Epos Raid Tools who receives that message will respond with:
  ```lua
  {
    name           = "Player-Realm",
    class          = "DEATHKNIGHT",   -- e.g., player’s class in uppercase
    currency = {
      quantity         = <current amount>,
      totalEarned      = <lifetime earned>,
      maxQuantity      = <weekly cap>,
      canEarnPerWeek   = <boolean>,
      -- … any other fields you choose to include …
    },
    timestamp      = <Unix epoch>,      -- time of the data snapshot
    -- … any other custom data …
  }
