# ranks Mod

A simple but powerful rank/tag system for Luanti (Minetest) with colored chat prefixes, nametags, aliases, and per-rank privileges.

## Features

- Colored rank tags in chat (e.g. `Admin | <Player> message`)
- The `|` is colored the same as the rank name
- Support for aliases (e.g. `001` for `Admin`)
- Persistent storage (survives server restarts)
- Per-rank privileges system
- Nametag support
- Easy external editing of ranks via JSON files

---

## Installation

1. Download or clone this mod into your `mods/` folder
2. Enable the mod in your world (or add to `game.conf`)
3. Restart the server

The mod will automatically create a `ranks/` folder in your world directory.

---

## Commands

### For Admins (`ranks_admin` privilege)

#### Create a Rank

```txt
/ranks_create <rankname> <hexcolor> [alias]
```

Example:

```txt
/ranks_create Admin #9E2231 001
```

---

#### Assign a Rank

```txt
/ranks <player> <rankname|alias>
```

Examples:

```txt
/ranks Nexarith Admin
/ranks Nexarith 001
```

---

#### Remove a Player's Rank

```txt
/ranks <player>
```

---

#### List All Ranks

```txt
/ranks
```

---

#### Manage Rank Privileges

```txt
/ranks_priv <rank> <add|remove|list> [privilege]
```

Examples:

```txt
/ranks_priv Admin add interact
/ranks_priv Admin add fly
/ranks_priv Admin list
```

---

### For Players

#### View Your Rank

```txt
/myranks
```

Shows your current rank.

---

## File Structure

Inside your world folder:

```txt
ranks/
├── ranks.json
└── player_ranks.json
```

### Description

- `ranks.json` → Stores all ranks and settings
- `player_ranks.json` → Stores player rank assignments

---

## Example `ranks/ranks.json`

```json
{
  "Admin": {
    "color": "#9E2231",
    "privs": {
      "interact": true,
      "shout": true,
      "fly": true,
      "noclip": true
    },
    "alias": "001"
  },
  "Moderator": {
    "color": "#00FF00",
    "privs": {
      "interact": true,
      "shout": true
    },
    "alias": "mod"
  }
}
```

---

## Notes

- Only players with the `ranks_admin` privilege can create or manage ranks.
- Singleplayer and server admins receive this privilege automatically.
- JSON files can be edited manually while the server is offline.
- You may also use `/reload` if your server supports it.

---

## Credits
Nexarith
Made with ❤️ for the Luanti community.
