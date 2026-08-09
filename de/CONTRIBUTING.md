# Mitwirken bei Culpeo Studio

Vielen Dank für dein Interesse, zu **Culpeo Studio** beizutragen.

## Grundregeln

1. **Local-First-Fokus:** Lokale Inferenz, Speicher und Projektgrenzen müssen geschützt bleiben.
2. **Design-System:** Alle Flutter-UI-Arbeiten müssen das **CulpeoGrid System** nutzen (`SliverGridDelegateWithMaxCrossAxisExtent`, 12px/16px Padding, 8px/12px Gaps).
3. **Entkoppelte Architektur:** Geschäftslogik, gRPC-Services (`culpeostudio.*.v1`) und UI-Komponenten bleiben strikt getrennt.
4. **Verifikation vor PR:** Führe `flutter analyze`, `flutter test` und `go test ./...` aus, bevor du Änderungen einreichst.

## Quick Start für Entwickler

```bash
git clone https://github.com/culpeostudio/Culpeostudio.git
cd Culpeostudio
./start.sh
```

## Sicherheitslücken melden

Bitte melde Sicherheitslücken nicht über öffentliche GitHub-Issues, sondern vertraulich per E-Mail an:
`security@culpeohq.com`

Weitere Informationen findest du in [SECURITY.md](../SECURITY.md).

## Lizenz

Mit deiner Mitwirkung stimmst du zu, dass deine Beiträge unter der **GNU AGPL-3.0 Lizenz** lizenziert werden.
