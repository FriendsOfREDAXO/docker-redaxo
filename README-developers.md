# Dokumentation für Entwickelnde

Dieses Repo enthält alle Sourcen, Skripte und Workflows, um das Docker-Image für REDAXO (`friendsofredaxo/redaxo`) zu bauen und zu veröffentlichen.

## 1. Sourcen

Im Ordner `/source` befinden sich alle Vorlagen, die zum Bau der Images benötigt werden:

- **`Dockerfile`**  
  Das Dockerfile für alle Image-Varianten, die wir anbieten. Es enthält verschiedene Platzhalter, z. B. `%%PHP_VERSION_TAG%%`, `%%PACKAGE_URL%%`, die später von den Skripten mit passenden Inhalten ersetzt werden, bevor es veröffentlicht wird.
- **`docker-entrypoint.sh`**  
  Das Entrypoint-Skript funktioniert für alle Image-Varianten, ohne dass dynamische Ersetzungen notwendig sind. Es wird beim Durchlauf unserer Skripte lediglich an die richtigen Stellen kopiert, bevor es veröffentlicht wird.
- **`images.yml`**  
  Diese Konfigurationsdatei enthält alle notwendigen Informationen zu den Images, wie z. B. die Namen der Varianten (z. B. `5-stable`, `5-edge`), ergänzende Tags (z. B. `5`), URL und Hashwerte der verwendeten REDAXO-Versionen sowie die jeweils zu verwendenden PHP-Versionen.  
  🍄 Diese Datei wird regelmäßig angepasst, wenn neue REDAXO-Versionen oder PHP-Versionen erscheinen.


## 2. Skripte

…


## 3. Workflows

…


## Allgemeine Informationen

…
