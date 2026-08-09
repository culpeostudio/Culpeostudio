package memoryviewer

import "fmt"

func Page(title string) string {
	return fmt.Sprintf(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>%s</title>
  <style>
    :root {
      --bg: #f5efe7;
      --surface: rgba(255,255,255,0.72);
      --surface-strong: #fffaf2;
      --ink: #1e1d1b;
      --muted: #61584b;
      --line: rgba(82, 61, 33, 0.15);
      --accent: #0b7a75;
      --accent-soft: #d4f1ef;
      --warn: #b85c38;
      --shadow: 0 20px 45px rgba(49, 35, 18, 0.14);
      --radius: 18px;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      color: var(--ink);
      font-family: "IBM Plex Sans", "Segoe UI", sans-serif;
      background:
        radial-gradient(circle at top left, rgba(11,122,117,0.18), transparent 34%%),
        radial-gradient(circle at bottom right, rgba(184,92,56,0.16), transparent 28%%),
        linear-gradient(180deg, #f7f2ea, #efe4d4);
      min-height: 100dvh;
    }
    header {
      padding: 2rem 1.5rem 1rem;
      max-width: 1280px;
      margin: 0 auto;
    }
    h1 {
      margin: 0;
      font-size: clamp(2rem, 4vw, 3.6rem);
      line-height: 0.95;
      letter-spacing: -0.03em;
    }
    p.lead {
      max-width: 66ch;
      color: var(--muted);
      font-size: 1rem;
      line-height: 1.55;
    }
    .shell {
      max-width: 1280px;
      margin: 0 auto;
      padding: 1rem 1.5rem 2rem;
      display: grid;
      gap: 1rem;
      grid-template-columns: 300px minmax(0, 1fr) 360px;
    }
    .panel {
      background: var(--surface);
      backdrop-filter: blur(18px);
      border: 1px solid var(--line);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
      overflow: hidden;
    }
    .panel h2 {
      margin: 0;
      font-size: 1rem;
      letter-spacing: 0.02em;
      text-transform: uppercase;
      padding: 1rem 1.1rem;
      border-bottom: 1px solid var(--line);
      background: rgba(255,255,255,0.4);
    }
    .panel-body {
      padding: 1rem 1.1rem 1.2rem;
      display: grid;
      gap: 0.9rem;
    }
    .search-row {
      display: grid;
      grid-template-columns: minmax(0, 1fr) 140px 145px 170px 110px;
      gap: 0.75rem;
    }
    .token-row {
      display: grid;
      grid-template-columns: minmax(0, 1fr) 160px 120px;
      gap: 0.75rem;
    }
    input, select, button, textarea {
      font: inherit;
      border-radius: 12px;
      border: 1px solid rgba(29,29,27,0.14);
      padding: 0.75rem 0.95rem;
      background: rgba(255,255,255,0.9);
      color: var(--ink);
      transition: all 0.2s ease;
    }
    button {
      cursor: pointer;
      background: linear-gradient(135deg, var(--accent), #0f9d95);
      color: white;
      border-color: transparent;
      font-weight: 600;
    }
    button:hover { transform: translateY(-1px); }
    .list, .events {
      display: grid;
      gap: 0.75rem;
      max-height: 72dvh;
      overflow: auto;
      padding-right: 0.2rem;
    }
    .card {
      padding: 0.9rem;
      border-radius: 14px;
      background: rgba(255,255,255,0.76);
      border: 1px solid rgba(29,29,27,0.08);
    }
    .card strong { display: block; margin-bottom: 0.25rem; }
    .meta {
      color: var(--muted);
      font-size: 0.88rem;
      line-height: 1.45;
    }
    .pill {
      display: inline-flex;
      align-items: center;
      min-height: 28px;
      padding: 0 0.75rem;
      border-radius: 999px;
      background: var(--accent-soft);
      color: var(--accent);
      font-size: 0.85rem;
      margin-right: 0.35rem;
      margin-top: 0.35rem;
    }
    pre {
      margin: 0;
      white-space: pre-wrap;
      word-break: break-word;
      font-family: "IBM Plex Mono", monospace;
      font-size: 0.88rem;
      line-height: 1.55;
    }
    .timeline {
      display: grid;
      gap: 0.65rem;
    }
    .timeline-item {
      border-left: 3px solid var(--accent);
      padding-left: 0.85rem;
    }
    .warning {
      color: var(--warn);
      font-weight: 600;
    }
    @media (max-width: 1080px) {
      .shell { grid-template-columns: 1fr; }
      .search-row { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <header>
    <h1>%s</h1>
    <p class="lead">Hybrid search, timeline lookup, context injection preview and live memory events for the Go shadow package.</p>
  </header>
  <div class="shell">
    <section class="panel">
      <h2>Sessions</h2>
      <div class="panel-body">
        <button id="refreshSessions">Refresh Sessions</button>
        <div class="list" id="sessionsList"></div>
      </div>
    </section>
    <section class="panel">
      <h2>Search and Detail</h2>
      <div class="panel-body">
        <div class="token-row">
          <input id="apiToken" type="password" placeholder="Bearer token for /api/memory/*" />
          <input id="apiUserID" placeholder="user_id" />
          <button id="saveToken">Save Token</button>
        </div>
        <div class="search-row">
          <input id="searchQuery" placeholder="Search memory" />
          <select id="searchSource">
            <option value="">All sources</option>
            <option value="spark">Spark</option>
            <option value="chat">Chat</option>
            <option value="engine">Engine</option>
            <option value="marketplace">Marketplace</option>
          </select>
          <select id="searchLayer">
            <option value="">All layers</option>
            <option value="user_data">User data</option>
            <option value="project_data">Project data</option>
          </select>
          <select id="searchCategory">
            <option value="">All categories</option>
            <option value="status">Status</option>
            <option value="brainstorming">Brainstorming</option>
            <option value="aenderungsantrag">Aenderungsantrag</option>
          </select>
          <button id="runSearch">Search</button>
        </div>
        <div class="list" id="resultsList"></div>
        <div class="card">
          <strong>Context preview</strong>
          <pre id="contextPreview">Pick a session to preview context injection.</pre>
        </div>
        <div class="card">
          <strong>Timeline</strong>
          <div class="timeline" id="timelineView"></div>
        </div>
      </div>
    </section>
    <section class="panel">
      <h2>Live Stream</h2>
      <div class="panel-body">
        <div class="events" id="eventsList"></div>
      </div>
    </section>
  </div>
  <script>
    let selectedSessionId = "";
    const urlParams = new URLSearchParams(window.location.search);
    const tokenParam = urlParams.get("token");
    const userParam = urlParams.get("user_id");
    let apiToken = tokenParam || localStorage.getItem("memory_api_token") || "dev-memory-token";
    let apiUserID = userParam || localStorage.getItem("memory_user_id") || "local";

    function setupToken() {
      const tokenInput = document.getElementById("apiToken");
      const userInput = document.getElementById("apiUserID");
      tokenInput.value = apiToken;
      userInput.value = apiUserID;
      document.getElementById("saveToken").onclick = () => {
        apiToken = tokenInput.value.trim();
        apiUserID = userInput.value.trim() || "local";
        localStorage.setItem("memory_api_token", apiToken);
        localStorage.setItem("memory_user_id", apiUserID);
      };
      if (tokenParam) {
        localStorage.setItem("memory_api_token", tokenParam);
      }
      if (userParam) {
        localStorage.setItem("memory_user_id", userParam);
      }
    }

    async function apiFetch(input, options) {
      const next = options || {};
      next.headers = Object.assign({}, next.headers || {}, {
        "Authorization": "Bearer " + apiToken,
        "X-Memory-User-ID": apiUserID
      });
      const response = await fetch(input, next);
      if (response.status === 401) {
        throw new Error("Unauthorized: bearer token fehlt oder ist falsch.");
      }
      return response;
    }

    // Memory content is untrusted: always render it via textContent/append,
    // never via innerHTML, to prevent stored XSS.
    function metaLine(text) {
      const meta = document.createElement("div");
      meta.className = "meta";
      meta.textContent = text;
      return meta;
    }

    function cardParts(card, titleText, metaText, preText) {
      const strong = document.createElement("strong");
      strong.textContent = titleText;
      card.appendChild(strong);
      if (metaText !== undefined) card.appendChild(metaLine(metaText));
      if (preText !== undefined) {
        const pre = document.createElement("pre");
        pre.textContent = preText;
        card.appendChild(pre);
      }
      return card;
    }

    async function loadSessions() {
      const response = await apiFetch("/api/memory/sessions");
      const sessions = await response.json();
      const list = document.getElementById("sessionsList");
      list.innerHTML = "";
      sessions.forEach((session) => {
        const card = document.createElement("button");
        card.className = "card";
        card.style.textAlign = "left";
        const strong = document.createElement("strong");
        strong.textContent = session.id;
        card.appendChild(strong);
        const meta = document.createElement("div");
        meta.className = "meta";
        meta.append(
          "project: " + session.project,
          document.createElement("br"),
          "source: " + session.source,
          document.createElement("br"),
          "prompts: " + session.prompt_count + " | observations: " + session.observation_count
        );
        card.appendChild(meta);
        card.onclick = () => selectSession(session.id);
        list.appendChild(card);
      });
    }

    async function selectSession(sessionId) {
      selectedSessionId = sessionId;
      const response = await apiFetch("/api/memory/context/" + encodeURIComponent(sessionId));
      const context = await response.json();
      document.getElementById("contextPreview").textContent = context.injection_prompt || "No context available.";
    }

    async function runSearch() {
      const query = document.getElementById("searchQuery").value;
      const source = document.getElementById("searchSource").value;
      const layer = document.getElementById("searchLayer").value;
      const category = document.getElementById("searchCategory").value;
      const url = new URL("/api/memory/search", window.location.origin);
      if (query) url.searchParams.set("q", query);
      if (source) url.searchParams.set("source", source);
      if (layer) url.searchParams.set("layer", layer);
      if (category) url.searchParams.set("category", category);
      const response = await apiFetch(url);
      const results = await response.json();
      const list = document.getElementById("resultsList");
      list.innerHTML = "";
      results.forEach((result) => {
        const card = document.createElement("div");
        card.className = "card";
        cardParts(
          card,
          result.title,
          "kind: " + result.kind + " | source: " + result.source + " | layer: " + result.layer + " | category: " + (result.category || "") + " | score: " + result.score.toFixed(3),
          result.snippet
        );
        if (result.kind === "observation" && result.session_id) {
          card.onclick = async () => {
            selectedSessionId = result.session_id;
            await selectSession(result.session_id);
            await loadTimeline(result.session_id, result.ref_id);
          };
        }
        list.appendChild(card);
      });
    }

    async function loadTimeline(sessionId, observationId) {
      const url = new URL("/api/memory/timeline", window.location.origin);
      url.searchParams.set("session_id", sessionId);
      url.searchParams.set("observation_id", observationId);
      const response = await apiFetch(url);
      const timeline = await response.json();
      const view = document.getElementById("timelineView");
      view.innerHTML = "";
      timeline.forEach((item) => {
        const node = document.createElement("div");
        node.className = "timeline-item";
        cardParts(node, item.title || item.type, item.created_at, item.narrative);
        view.appendChild(node);
      });
    }

    async function attachEvents() {
      let ticket = "";
      try {
        const res = await apiFetch("/api/memory/events/ticket", { method: "POST" });
        if (!res.ok) {
          throw new Error("HTTP " + res.status);
        }
        const data = await res.json();
        ticket = data.ticket;
      } catch (err) {
        console.error("Failed to fetch event ticket:", err);
        const node = document.createElement("div");
        node.className = "card warning";
        node.textContent = "Live stream unavailable without an event ticket.";
        document.getElementById("eventsList").prepend(node);
        return;
      }

      const eventURL = new URL("/memory/events", window.location.origin);
      eventURL.searchParams.set("ticket", ticket);
      connectEventSource(eventURL);
    }

    function connectEventSource(url) {
      const events = new EventSource(url);
      const target = document.getElementById("eventsList");
      events.onmessage = (event) => {
        const card = document.createElement("div");
        card.className = "card";
        cardParts(card, "message", undefined, event.data);
        target.prepend(card);
      };
      ["session_created","prompt_added","observation_added","change_request_updated","memory_compressed","session_completed","session_deleted"].forEach((type) => {
        events.addEventListener(type, (event) => {
          let text = event.data;
          try {
            text = JSON.stringify(JSON.parse(event.data), null, 2);
          } catch (err) {}
          const card = document.createElement("div");
          card.className = "card";
          cardParts(card, type, undefined, text);
          target.prepend(card);
        });
      });
      events.onerror = () => {
        events.close();
        setTimeout(attachEvents, 5000);
        const node = document.createElement("div");
        node.className = "card warning";
        node.textContent = "Live stream disconnected, retrying...";
        target.prepend(node);
      };
    }

    document.getElementById("refreshSessions").onclick = loadSessions;
    document.getElementById("runSearch").onclick = runSearch;
    setupToken();
    loadSessions();
    attachEvents();
  </script>
</body>
</html>`, title, title)
}
