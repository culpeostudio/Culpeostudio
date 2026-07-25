package philox

import (
	"path/filepath"
	"strings"
)

// ── Frontend context detection ──────────────────────────────────────────────

// frontendMessageKeywords are terms in a user message that signal frontend/UI work.
var frontendMessageKeywords = []string{
	// German UI terms
	"login-seite", "login seite", "loginseite", "anmeldeseite", "registrierungsseite",
	"dashboard", "startseite", "landing page", "landingpage",
	"formular", "kontaktformular", "eingabefeld", "sidebar", "navbar", "navigation",
	"webseite", "website", "webpage", "homepage",
	"dark mode", "darkmode", "light mode", "lightmode",
	"responsive", "mobile ansicht", "tablet ansicht",
	"animation", "animationen", "uebergang", "transition",
	"modal", "dialog", "popup", "toast", "notification",
	"karte", "card", "cards", "karten",
	"tabelle", "table", "grid", "layout",
	"button", "buttons", "icon", "icons",
	"header", "footer", "hero",
	"profil", "profilseite", "settings-seite", "einstellungen-seite",

	// English UI terms
	"login page", "signup page", "sign-up page", "register page",
	"landing page", "home page",
	"frontend", "front-end", "front end",
	"user interface", "ui design", "web app", "webapp", "web application",
	"glassmorphism", "neumorphism", "glaseffekt",
	"tailwind", "bootstrap", "material design",
	"component", "komponente",
	"css", "stylesheet", "styling",
	"dark theme", "light theme",
}

// frontendFileExtensions are file extensions that indicate frontend code.
var frontendFileExtensions = map[string]bool{
	".html":   true,
	".htm":    true,
	".css":    true,
	".scss":   true,
	".sass":   true,
	".less":   true,
	".jsx":    true,
	".tsx":    true,
	".vue":    true,
	".svelte": true,
	".astro":  true,
}

// detectFrontendContext checks whether the current session involves frontend work.
// It scans the user message for UI keywords and the session for frontend file extensions.
func detectFrontendContext(session *PersistedSession, userMessage string) bool {
	if hasFrontendKeywords(userMessage) {
		return true
	}
	if hasFrontendFilesInSession(session) {
		return true
	}
	return false
}

// hasFrontendKeywords checks if the user message contains frontend-related terms.
func hasFrontendKeywords(message string) bool {
	lower := strings.ToLower(message)
	for _, keyword := range frontendMessageKeywords {
		if strings.Contains(lower, keyword) {
			return true
		}
	}
	return false
}

// hasFrontendFilesInSession checks recent tool activity for frontend file extensions.
func hasFrontendFilesInSession(session *PersistedSession) bool {
	// Check tool audit (recent tool calls).
	auditLimit := len(session.ToolAudit)
	if auditLimit > 20 {
		auditLimit = 20
	}
	for i := len(session.ToolAudit) - 1; i >= len(session.ToolAudit)-auditLimit && i >= 0; i-- {
		audit := session.ToolAudit[i]
		if audit.Arguments == nil {
			continue
		}
		if path, ok := audit.Arguments["path"].(string); ok {
			if isFrontendFile(path) {
				return true
			}
		}
	}

	// Check recent messages for file paths in tool results.
	msgLimit := len(session.Messages)
	if msgLimit > 16 {
		msgLimit = 16
	}
	for i := len(session.Messages) - 1; i >= len(session.Messages)-msgLimit && i >= 0; i-- {
		msg := session.Messages[i]
		if msg.Role == "user" && hasFrontendKeywords(msg.Content) {
			return true
		}
		for _, tc := range msg.ToolCalls {
			if isFrontendFile(tc.Function.Arguments) {
				return true
			}
		}
	}

	return false
}

// isFrontendFile checks if a path has a frontend file extension.
func isFrontendFile(path string) bool {
	ext := strings.ToLower(filepath.Ext(strings.TrimSpace(path)))
	return frontendFileExtensions[ext]
}

// ── Modern design system prompt ─────────────────────────────────────────────

func frontendDesignInstruction() string {
	return strings.TrimSpace(`## Frontend & UI Design (aktiv weil Frontend-Kontext erkannt)
Du erstellst oder bearbeitest Frontend-Code. Nutze IMMER modernes, professionelles Design.

### CSS & Styling
- CSS Custom Properties (--color-primary, --radius, --shadow etc.) fuer konsistentes Theming
- Nutze clamp() fuer responsive Schriftgroessen: font-size: clamp(0.875rem, 1.5vw, 1.125rem)
- Vermeide feste Pixel-Werte fuer Layout — nutze rem, em, %, vw/vh, dvh
- gap statt margin fuer Abstaende zwischen Elementen (Flexbox/Grid gap)
- Container Queries (@container) wo sinnvoll fuer komponentenbasiertes responsive Design
- aspect-ratio fuer Medien und Karten
- Smooth transitions auf ALLE interaktiven Elemente: transition: all 0.2s ease

### Visuelle Effekte
- Glassmorphism: backdrop-filter: blur(12px) mit semi-transparentem Hintergrund (rgba/hsla mit 0.1-0.3 alpha)
- Subtile Schatten statt harter Raender: box-shadow mit mehreren Layern fuer Tiefe
- Weiche Gradienten: linear-gradient mit mindestens 2 Stops fuer Hintergruende
- Hover-Effekte: transform: translateY(-2px) + box-shadow Erhoehung fuer Karten/Buttons
- Focus-Styles: outline mit offset und Farbe passend zum Theme, niemals outline: none ohne Ersatz
- Border-Radius: abgerundete Ecken, mindestens 8px fuer Karten, 6px fuer Inputs, 9999px fuer Pills

### Farbschema
- Definiere ein konsistentes Farbschema mit CSS Custom Properties
- Dark Mode als Default oder mit prefers-color-scheme Media Query
- Farbhierarchie: Primary, Secondary, Accent, Surface, Background, Text, Muted
- Kontrastverhältnis WCAG AA einhalten: Text auf Hintergrund mindestens 4.5:1
- Nutze hsl() oder oklch() fuer Farben — leichter zu variieren als hex

### Layout
- CSS Grid fuer Seitenlayout, Flexbox fuer Komponentenlayout
- Mobile-first: Basis-Layout fuer kleine Screens, Erweiterung mit min-width Media Queries
- Logische Properties: margin-inline, padding-block statt margin-left/right wo moeglich
- max-width: 1200px mit margin-inline: auto fuer zentrierte Container
- min-height: 100dvh fuer Vollbildlayouts

### Formulare & Inputs
- Inputs: padding: 0.75rem 1rem, border: 1px solid mit subtiler Farbe, border-radius: 8px
- Focus: ring-artige Hervorhebung mit box-shadow statt nur border-color
- Placeholder mit reduzierter Opacity (0.5-0.6)
- Labels immer sichtbar, nicht nur als Placeholder
- Buttons: min-height: 44px fuer Touch-Targets, klare Primaer/Sekundaer-Hierarchie
- Disabled-States: opacity: 0.5 + cursor: not-allowed

### Typografie
- System Font Stack: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif
- Oder Inter/Geist von Google Fonts fuer modernen Look
- Klare Hierarchie: h1 deutlich groesser als h2, mindestens 3 unterscheidbare Stufen
- line-height: 1.5 fuer Fliesstext, 1.2 fuer Ueberschriften
- letter-spacing: -0.02em fuer grosse Ueberschriften, normal fuer Body

### Animationen
- Micro-Interactions: Buttons, Links, Karten reagieren auf hover/focus/active
- Einblende-Animationen: opacity 0->1 + translateY(8px)->0 fuer erscheinende Elemente
- Ladeanimationen: CSS-only Spinner oder Skeleton Screens statt leerer Flaechen
- Dauer: 150-300ms fuer UI-Feedback, 300-500ms fuer Seitenuebergaenge
- Easing: ease-out fuer Einblendungen, ease-in-out fuer Bewegungen
- prefers-reduced-motion respektieren: @media (prefers-reduced-motion: reduce)

### Was du NICHT tun sollst
- Keine inline-styles — nutze CSS-Klassen oder scoped styles
- Kein veraltetes Design: keine harten 1px Borders ohne Radius, keine grauen Default-Buttons
- Keine riesigen Bibliotheken importieren wenn 30 Zeilen Custom-CSS reichen
- Keine !important Hacks
- Keine unbeschrifteten Icon-Buttons ohne aria-label`)
}
