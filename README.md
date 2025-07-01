# Epos Raid Tools

**Epos Raid Tools** is a World of Warcraft addon that gives raid leaders and officers a single dashboard for rosters, custom-currency tracking, WeakAuras, AddOn compliance, and per-boss group setups. It auto-scans your guild roster, exchanges data over AceComm, and shows everything in a clean, scrollable UI—complete with role filters, blacklists, and one-click “Request Data” or “Apply Roster” buttons.

---

## Table of Contents

1. [Features](#features)
2. [Installation](#installation)
3. [Usage](#usage)
   - [Guild Roster](#guild-roster)
   - [Crests Tab](#crests-tab)
   - [WeakAuras Tab](#weakauras-tab)
   - [AddOns Tab](#addons-tab)
   - [Setup Tab](#setup-tav)
   - [Requesting & Receiving Data](#requesting--receiving-data)
4. [Configuration & Saved Variables](#configuration--saved-variables)
5. [File Structure](#file-structure)
6. [License](#license)

---

## Features

- **Automatic Guild Roster Scanning**
  - On login or whenever the guild roster updates, the addon builds a list of max‐level guild members (via `fetchGuild`).
  - Stores each member’s name, rank, level, and class in `EposRT.GuildRoster`.

- **Live Crests Data Fetching**
  - Uses AceComm-3.0 to listen for `“EPOSDATABASE”` messages.
  - When a trusted sender pushes a compressed/serialized payload, the addon decodes it and updates `EposRT.Crests`.
   
- **Live AddOns Data Fetching**
  - Uses AceComm-3.0 to listen for `“EPOSDATABASE”` messages.
  - When a trusted sender pushes a compressed/serialized payload, the addon decodes it and updates `EposRT.Addons`.
 
- **Live WeakAuras Data Fetching**
  - Uses AceComm-3.0 to listen for `“EPOSDATABASE”` messages.
  - When a trusted sender pushes a compressed/serialized payload, the addon decodes it and updates `EposRT.WeakAuras`.
 
- **Setup Management**
   -  Export setup string via google sheets and import it in EposRT to manage setups with a single click.

- **Role-Based Filters & Blacklists**
  - Only tracks guild members whose rank is enabled in Roles Management and who are not blacklisted.
  - Easily add or remove players from the blacklist to exclude them from all tabs.

- **Clean, Scrollable UI**
  - Two main tabs: **Roster** (status tracking) and **Crests** (currency tracking).
  - On-demand “Request Data” buttons to fetch the latest information from peers running the addon.

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

### AddOns Tab

1. Switch to the **AddOns** tab to see whether each tracked AddOn folder is present on every player.
2. Columns in the **AddOns** tab:
   - **Name** – player name and realm  
   - **Installed** – green “True” if the folder exists, red “False” if missing  
   - **Version** – string taken from the AddOn’s `## Version` field (or “-”)  
   - **Loaded** – green “True” if the AddOn is loaded on the sender’s client  
   - **Updated** – timestamp of last data received via AceComm  

3. **AddOns Options**  
   - Click **AddOns Options** (top-left) to build a fetch list of AddOn folders (e.g. `WeakAuras`, `Details`).  
   - The dropdown at the top of the tab lets you pick which folder’s data to display.

4. **Request Data**  
   - Click **Request Data** (top-right) to broadcast a query; every guildmate running Epos Raid Tools will reply with their current AddOn payload for the selected folder.

---

### WeakAuras Tab

1. Open the **WeakAuras** tab to check if a specific WA set is installed on each player.
2. Columns in the **WeakAuras** tab:
   - **Name** – player name and realm  
   - **Installed** – green “True” or red “False”  
   - **Version** – SemVer string from the WA table (or “-”)  
   - **Loaded** – green if the aura is loaded, red if disabled/not loaded  
   - **Updated** – timestamp of last data received  

3. **WeakAuras Options**  
   - Click **WeakAuras Options** (top-left) to manage the list of WA set IDs to track.  
   - Use the dropdown to choose which set is currently displayed.

4. **Request Data**  
   - Click **Request Data** (top-right) to poll all online guildmates for the selected WA set.

---

### Setups Tab

1. Select the **Setups** tab to view or edit *per-boss* raid rosters (Groups 1-8).  
   A roster has five columns: **Tanks**, **Healers**, **Melee**, **Ranged**, and **Benched** (Groups 5-8).

2. Buttons & controls:
   - **Setup Options** (top-left) – import/export JSON, rename bosses, reorder the boss list.
   - **Boss dropdown** – choose which boss roster is currently shown.
   - **Apply Roster** – pushes the visible 40-slot list to the live raid via  
     `Epos:ApplyGroups(list)` → `ProcessRoster()`, which automatically:
       1. Moves players to their target groups.  
       2. Swaps members to resolve full groups.  
       3. Performs three-way bridge swaps to place everyone in the exact 1-5 slot.  
       4. Skips if anyone in the raid is in combat or if the raid leader is locked to a group.

3. Colour coding:
   - Every name is class-coloured (data pulled from `EposRT.GuildRoster`).  
   - Empty slots render as blank cells.

4. Tip: if you update the JSON file from your Google Sheet, simply hit **Setup Options → Import** and click **Apply Roster** again to refresh the raid groups.

---

### Data Source
1. WeakAura Dependency:
  - Epos Raid Tools only collects and displays data that is broadcast by a compatible WeakAura.
  - All raid members must have the specified WeakAura installed and enabled for EposRT to gather their data.
  - You can find the WeakAura used by this addon here: https://wago.io/6PHcVWmPg

2. Data Format:
   - When Request Data is clicked, the addon listens for EPOSDATABASE messages and expects payloads containing: Data (See Section Below)
   - Without the WeakAura sending this table, no data will appear in the tabs.
  
---

## Requesting & Receiving Data

- Whenever you click **Request Data**, Epos Raid Tools broadcasts an AceComm message on channel `“EPOSDATABASE”`.
- Any other player running Epos Raid Tools who receives that message will respond with:
  ```lua
  {
    name           = "Bluupriest-Blackhand",
    class          = "Priest",
    currency       = { ...C_CurrencyInfo.GetCurrencyInfo(PAYLOAD_IDS) },
    weakauras      = { ...WeakAuras.GetData(PAYLOAD_IDS) },
    addons         = { ...GetAddOnMetadata(PAYLOAD_IDS) },
    timestamp      = <Unix>,
  }
