package philobot

import (
	"fmt"
	"strings"
)

// truncationSuspicionChars ist die Laenge, ab der ein fehlendes Folgefeld
// eher an einer abgeschnittenen Modell-Antwort liegt als an Unkenntnis.
const truncationSuspicionChars = 600

// truncationAwareHint liefert den Argument-Hinweis - und erkennt dabei den
// haeufigsten Fall: die Antwort des Modells wurde mitten im JSON
// abgeschnitten.
//
// Ein Modell, das eine ganze Funktion als old_text schickt, verbraucht sein
// Token-Budget, bevor es new_text schreiben kann. Der Aufruf kommt dann ohne
// new_text an. Der generische Hinweis "Erwarte new_text" hilft da nicht - das
// Modell weiss das, es kam nur nicht so weit. Es muss stattdessen kleiner
// schneiden.
func truncationAwareHint(toolName string, args map[string]interface{}) string {
	if toolName != "patch_file" && toolName != "write_file" {
		return fileToolArgumentHint(toolName)
	}

	longest := 0
	for _, key := range []string{"old_text", "content", "new_text"} {
		if text, ok := args[key].(string); ok && len(text) > longest {
			longest = len(text)
		}
	}
	if longest < truncationSuspicionChars {
		return fileToolArgumentHint(toolName)
	}

	return fmt.Sprintf(
		"Deine Antwort wurde nach %d Zeichen abgeschnitten, das Folgefeld fehlt deshalb. "+
			"Ersetze nicht ganze Funktionen: waehle als old_text die kleinste eindeutige Stelle "+
			"(oft 2-3 Zeilen) und arbeite in mehreren patch_file-Aufrufen. %s",
		longest, fileToolArgumentHint(toolName))
}

// argumentAliases bildet gaengige Feldnamen auf die Namen ab, die die
// Werkzeuge tatsaechlich erwarten.
//
// Kleinere Modelle treffen den Feldnamen oft nicht: sie schicken bei
// find_files ein "glob" oder "query" statt "pattern", bei read_file ein
// "file" statt "path". Fachlich meinen sie dasselbe. Ohne diese
// Uebersetzung scheitert der Aufruf, das Modell versucht es wortgleich
// noch einmal und verbraucht so das Rundenbudget des Schritts - genau
// das war in der Praxis zu beobachten.
//
// Die Zuordnung ist bewusst eng gehalten: nur eindeutige Synonyme, keine
// Ratespiele. Ein unbekanntes Feld bleibt ein Fehler, damit echte
// Missverstaendnisse nicht unter den Teppich geraten.
var argumentAliases = map[string]map[string]string{
	"find_files": {
		"glob": "pattern", "query": "pattern", "name": "pattern",
		"filename": "pattern", "file_pattern": "pattern", "search": "pattern",
	},
	"grep_search": {
		"query": "pattern", "search": "pattern", "text": "pattern",
		"regex": "pattern", "search_term": "pattern", "needle": "pattern",
	},
	"read_file": {
		"file": "path", "filepath": "path", "file_path": "path", "filename": "path",
	},
	"list_dir": {
		"dir": "path", "directory": "path", "folder": "path", "dir_path": "path",
	},
	"stat_path": {
		"file": "path", "filepath": "path", "file_path": "path",
	},
	"write_file": {
		"file": "path", "filepath": "path", "file_path": "path",
		"text": "content", "data": "content", "body": "content",
	},
	"patch_file": {
		"file": "path", "filepath": "path", "file_path": "path",
		"old": "old_text", "new": "new_text",
		"old_string": "old_text", "new_string": "new_text",
		"search": "old_text", "replace": "new_text",
	},
	"make_dir": {
		"dir": "path", "directory": "path", "folder": "path",
	},
	"delete_path": {
		"file": "path", "filepath": "path", "file_path": "path", "target": "path",
	},
	"move_path": {
		"source": "source_path", "from": "source_path", "src": "source_path",
		"destination": "destination_path", "to": "destination_path", "dest": "destination_path",
	},
	"run_command": {
		"cmd": "command", "program": "command", "executable": "command",
		"arguments": "args", "argv": "args",
	},
}

// normalizeToolArguments uebersetzt bekannte Feldnamen-Varianten auf die
// erwarteten Namen. Der kanonische Name gewinnt immer: schickt ein Modell
// beides, bleibt der richtige Wert stehen.
func normalizeToolArguments(toolName string, args map[string]interface{}) map[string]interface{} {
	aliases, known := argumentAliases[toolName]
	if !known || len(args) == 0 {
		return args
	}

	out := make(map[string]interface{}, len(args))
	for key, value := range args {
		out[key] = value
	}
	for alias, canonical := range aliases {
		value, hasAlias := out[alias]
		if !hasAlias {
			continue
		}
		if existing, hasCanonical := out[canonical]; hasCanonical {
			// Kanonisches Feld ist gesetzt und nicht leer: Alias verwerfen.
			if text, isText := existing.(string); !isText || strings.TrimSpace(text) != "" {
				delete(out, alias)
				continue
			}
		}
		out[canonical] = value
		delete(out, alias)
	}
	return out
}
