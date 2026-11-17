# ViewYork Media: Mac-Setup

Richtet einen neuen Mac im ViewYork-Standard ein: Programme, Dock, Screenshots, Scrollrichtung, Hintergrund- und Profilbild.

## Start auf dem neuen Mac

Terminal öffnen und diese Zeile einfügen (Gerätename anpassen):

```
curl -fsSLo ~/setup.sh https://raw.githubusercontent.com/york-cloud/vym-mac-setup/main/setup.sh && zsh ~/setup.sh --name "VYM-Chrysler"
```

Nach der Chrome-Anmeldung das Dock vervollständigen:

```
zsh ~/setup.sh --dock
```

## Inhalt

- `setup.sh`: das Skript. Der ViewYork-Standard (Programme, Dock-Größe) steht oben im Abschnitt Einstellungen.
- `assets/vym-hintergrund.png`: Hintergrundbild, 3456 x 2234 Pixel.
- `assets/vym-profilbild.png`: Profilbild für das Benutzerkonto.

## Hinweise

- Das Skript enthält keine Passwörter und meldet niemanden an.
- Es kann beliebig oft laufen, bereits Installiertes wird übersprungen.
- Protokoll auf dem Mac: `~/Library/Logs/vym-mac-setup.log`
- Gerätenamen folgen dem Schema `VYM-Gebäude` (Gebäude in New York), die Vergabe steht in der Inventarliste in Notion.
