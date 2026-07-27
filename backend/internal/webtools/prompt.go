package webtools

import "strings"

// PromptSection liefert die Werkzeug-Anleitung fuer den System-Prompt.
//
// Der Text ist der eigentliche Hebel dafuer, dass ein Modell die
// Websuche sinnvoll einsetzt: er nennt nicht nur die Aufrufsyntax,
// sondern vor allem die Entscheidungskriterien. Ohne explizite
// Nicht-Faelle suchen kleinere Modelle bei jeder Frage, was Zeit
// kostet und schlechtere Antworten liefert als ihr eigenes Wissen.
//
// hasFileTools steuert, wohin das Modell bei Fragen zum Code des
// Nutzers verwiesen wird: auf die Datei-Werkzeuge (Projekt-Modus)
// oder auf eine ehrliche Absage (Chat ohne Projekt).
func PromptSection(hasFileTools bool) string {
	var b strings.Builder
	b.WriteString("## Web-Werkzeuge\n")
	b.WriteString("Du kannst im Internet suchen und Seiten lesen:\n")
	b.WriteString("- " + ToolWebSearch + " {\"query\":\"...\"} — Websuche. Optional \"max_results\" (1-10, Standard 5) und \"category\" (\"text\" oder \"news\")\n")
	b.WriteString("- " + ToolWebFetch + " {\"url\":\"https://...\"} — Seiteninhalt als Markdown lesen. Optional \"max_chars\" (Standard 6000)\n")

	b.WriteString("\n### Wann du suchen sollst\n")
	b.WriteString("Entscheide selbst, ob eine Suche die Antwort wirklich verbessert. Suche, wenn:\n")
	b.WriteString("- die Frage aktuelle Ereignisse, Preise, Versionen oder Releases betrifft\n")
	b.WriteString("- es um Software geht, die nach deinem Wissensstand erschienen sein koennte\n")
	b.WriteString("- du eine konkrete Fehlermeldung, API-Signatur oder Doku-Stelle brauchst\n")
	b.WriteString("- du dir unsicher bist und eine falsche Antwort teuer waere\n")

	b.WriteString("\n### Wann du NICHT suchen sollst\n")
	b.WriteString("- Allgemeinwissen und Grundlagen, die du sicher beherrschst\n")
	if hasFileTools {
		b.WriteString("- Fragen zum Code oder zu Dateien des Nutzers — dafuer sind die Datei-Werkzeuge da\n")
	} else {
		b.WriteString("- Fragen zum Code des Nutzers — ohne geoeffnetes Projekt siehst du seine Dateien nicht, sag das ehrlich\n")
	}
	b.WriteString("- reine Meinungs-, Rechen- oder Formulierungsaufgaben\n")
	b.WriteString("- wenn du dieselbe Suche in diesem Gespraech schon gemacht hast\n")

	b.WriteString("\n### So arbeitest du damit\n")
	b.WriteString("1. Formuliere praezise Suchbegriffe statt ganzer Fragesaetze.\n")
	b.WriteString("2. Lies die Trefferliste. Die Snippets sind gekuerzt — reichen sie fuer die Antwort, ist die Suche fertig.\n")
	b.WriteString("3. Nur wenn du Details brauchst, hol dir mit " + ToolWebFetch + " die vielversprechendste Seite.\n")
	b.WriteString("4. Nenne in deiner Antwort die Quelle als URL, damit der Nutzer nachpruefen kann.\n")
	b.WriteString("5. Findest du nichts Brauchbares, sag das ehrlich, statt zu raten.\n")
	b.WriteString("Halte dich kurz: hoechstens zwei Suchen und zwei Seitenabrufe pro Frage.\n")
	b.WriteString("\nWICHTIG: Kommentiere deine Recherche nicht. Kein \"Plan:\", keine Aufzaehlung ")
	b.WriteString("deiner naechsten Schritte, keine Zwischenanalyse der Treffer — der Nutzer sieht ")
	b.WriteString("jedes Wort davon. Rufe das Werkzeug auf oder gib die fertige Antwort.\n")
	return b.String()
}
