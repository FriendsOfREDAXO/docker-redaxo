# Dokumentation für Entwickelnde

Dieses Repo enthält alle Sourcen, Skripte und Workflows, um die 🐳 Docker-Images für REDAXO (`friendsofredaxo/redaxo`) zu bauen und zu veröffentlichen.

Inhaltsverzeichnis:
* [Projektstruktur](#projektstruktur)
* [Aufgaben und Abläufe](#aufgaben-und-abläufe)


## Projektstruktur

### 1. Sourcen

Im Ordner `/source` befinden sich alle Vorlagen, die zum Bau der Images benötigt werden:

- **[`Dockerfile`](https://github.com/FriendsOfREDAXO/docker-redaxo/blob/main/source/Dockerfile)**  
  Das Dockerfile für alle Image-Varianten, die wir anbieten. Es enthält verschiedene Platzhalter, z. B. `%%PHP_VERSION_TAG%%`, `%%PACKAGE_URL%%`, die später von den Skripten mit passenden Inhalten ersetzt werden, bevor es veröffentlicht wird.
- **[`docker-entrypoint.sh`](https://github.com/FriendsOfREDAXO/docker-redaxo/blob/main/source/docker-entrypoint.sh)**  
  Das Entrypoint-Skript funktioniert aktuell für alle Image-Varianten, ohne dass dynamische Ersetzungen notwendig sind. Es wird beim Durchlauf unserer Skripte lediglich an die richtigen Stellen kopiert, bevor es veröffentlicht wird.
- **[`images.yml`](https://github.com/FriendsOfREDAXO/docker-redaxo/blob/main/source/images.yml)**  
  Diese Konfigurationsdatei enthält alle notwendigen Informationen zu den Images, wie z. B. die Namen der Varianten (z. B. `5-stable`, `5-edge`), ergänzende Tags (z. B. `5`), URL und Hashwerte der verwendeten REDAXO-Versionen sowie die jeweils zu verwendenden PHP-Versionen.  
  🍄 Diese Datei wird regelmäßig von uns angepasst, wenn neue REDAXO-Versionen oder PHP-Versionen erscheinen.


### 2. Skripte

Im Ordner `/scripts` befinden sich Skripte für verschiedene Zwecke. Aktuell ist es nur eins:

- **[`generate-image-files.ts`](https://github.com/FriendsOfREDAXO/docker-redaxo/blob/main/scripts/generate-image-files.ts)**  
  Das Skript liest die Konfigurationsdatei (`images.yml`) ein, um anschließend für jede darin enthaltene Image-Variante einen Ordner unter `/images` anzulegen mit allen Dateien, die für das Bauen und Veröffentlichen benötigt werden. Platzhalter werden dabei ersetzt, wie oben beschrieben, und es wird eine zusätzliche YML-Datei `tags.yml` erstellt, die Angaben zu den Docker-Tags enthält.

🍄 Wir benutzen [Deno](https://deno.com/) für die Skripte. Damit lassen sich recht einfach YML-Dateien auslesen, Platzhalter ersetzen und Aktionen im Dateisystem vornehmen. Womöglich einfacher als mit klassischen Shell-Skripten.


### 3. Images

Im Ordner `/images` liegen die finalen Baupläne für die verschiedenen Varianten unserer Docker-Images. Diese werden vollständig mit Hilfe der Skripte und Workflows generiert, so dass wir hier keine manuellen Anpassungen vornehmen.


### 4. Workflows

Im Ordner `.github/workflows` befinden sich die [GitHub-Workflows](https://docs.github.com/en/actions/using-workflows/about-workflows):

- **[`generate.yml`](https://github.com/FriendsOfREDAXO/docker-redaxo/blob/main/.github/workflows/generate.yml)**  
  Der Workflow springt an, wenn innerhalb eines PRs Änderungen an den Sourcen (`/source`) vorgenommen worden sind. Er benutzt das oben beschriebene Skript zum Generieren der Images und committet die daraus entstehenden Änderungen in `/images` automatisch.
- **[`test.yml`](https://github.com/FriendsOfREDAXO/docker-redaxo/blob/main/.github/workflows/test.yml)**  
  Springt an, wenn innerhalb eines PRs die Images anpasst worden sind, also üblicherweise nach Durchlauf des Generate-Workflows. Er baut einmal testweise die neu generierten Images und stellt damit sicher, dass diese fehlerfrei starten.
- **[`publish.yml`](https://github.com/FriendsOfREDAXO/docker-redaxo/blob/main/.github/workflows/publish.yml)**  
  Dieser Workflow hört auf den main-Branch und erwartet dort Änderungen an den Images. Das ist üblicherweise der Fall, wenn PRs gemerged worden sind.  
  Der Workflow ist etwas aufwendiger als die anderen, denn er durchläuft mehrere Schritte: Zuerst wird eine Liste von Tags generiert. Anschließend werden alle Varianten der Images gebaut und in den beiden Registries (Docker Hub und GitHub Container Repository, GHCR) veröffentlicht. Die Beschreibung aus der [`README.md`](https://github.com/FriendsOfREDAXO/docker-redaxo/blob/main/README.md) wird danach zum Docker Hub übertragen. Und schließlich werden alle Images innerhalb des GHCR gelöscht, die nun keine Tags mehr haben, also _untagged_ sind, weil zuvor neue Images veröffentlicht worden sind. Das alles dauert etwa 15–20 Minuten.  


## Aufgaben und Abläufe

Was ist zu tun und auf welche Art tun wir es?

### REDAXO oder PHP aktualisieren

Dafür braucht es lediglich einen Pull Request mit Anpassungen in [`/source/images.yml`](https://github.com/FriendsOfREDAXO/docker-redaxo/blob/main/source/images.yml). Innerhalb des PRs erfolgt dann ein Testing mittels GitHub Workflows, und nach dem Merge des PR werden die neuen Images automatisch publiziert.

### Tools und Workflows aktualisieren

Deno könnte hin und wieder aktualisiert werden, muss aber nicht. Gleiches gilt für die verwendeten GitHub Actions innerhalb der Workflows.

### Docker-Images aktualisieren

Sofern sich bei REDAXO nichts Neues ergibt, müssen auch die Docker-Images nicht unbedingt aktualisiert werden. 

Allerdings kann es sinnvoll sein, hin und wieder den Publish-Workflow manuell anzustoßen (»workflow dispatch«), damit sich die von uns verwendeten Bestandteile aktualisieren wie z. B. Apache, PHP, Extensions und anderes. Die Funktion dafür ist oben rechts auf der Seite für [Actions > Publish](https://github.com/FriendsOfREDAXO/docker-redaxo/actions/workflows/publish.yml).

Nach Veröffentlichung neuer Images bleiben in der Regel ältere Images zurück, die dann keinen Tag mehr haben (»untagged images«). Diese können gelöscht werden, weil sie ohne Tag keine Verwendung finden und unnötigen Platz einnehmen. Innerhalb des GHCR werden solche untagged Images automatisch beim Durchlauf des Workflows entfernt, jedoch haben wir für den Docker Hub aktuell keinen Automatismus dafür. Deshalb bietet sich an, hin und wieder manuell innerhalb der Weboberfläche aufzuräumen.
