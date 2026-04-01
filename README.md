# Raw Denim Tracker

An Android app for tracking raw denim garments — wear days, washes, and fading progress.

## Features

- **Garment management** — Add jeans, shirts, or any raw denim piece with brand, model, size, first wear date, photo, and notes
- **Wear day tracking** — Log individual wear days, including historical days worn before you started tracking
- **Wash logging** — Record washes with date and temperature
- **Quick log from home screen** — Add today's wear day directly from the garment list without opening the detail view
- **NFC tag support** — Link an NFC tag to a garment; scanning it automatically logs a wear day for today
- **Home screen widget** — Glanceable wear day count for your selected garment, right on your home screen
- **Home Assistant integration** — Pushes the currently worn garment (name + total wear days) to a Home Assistant sensor via REST API
- **Location tracking** — Optionally records your location when logging a wear day; tap the pin icon on any entry to see it on an OpenStreetMap map
- **Google Sheets sync** — Export all data to a Google Sheet with a Dashboard, per-item stats, wear day chart, and coordinates
- **Backup & restore** — Export and import a full JSON backup of all your data
- **Sorting** — Sort garments by first worn date, wear days, brand, or last worn — ascending or descending

## Download

Get the latest APK from the [Releases](https://github.com/HACucoo/Raw-Denim-Tracker/releases) page.

> Enable *Install from unknown sources* on your Android device before installing.

## Tech Stack

Flutter · Riverpod · SQLite · Google Sheets API · NFC Manager · Home Widget · Geolocator · flutter_map (OpenStreetMap)
