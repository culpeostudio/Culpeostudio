# Security Policy

## Reporting a vulnerability

Please report security issues **privately** to <security@culpeohq.com> —
not through a public issue, so the problem can be fixed before it becomes
widely known.

Helpful in a report:

- what the issue is and what an attacker could achieve with it
- steps to reproduce (a minimal example is ideal)
- affected version or commit

You will get an acknowledgement within **72 hours** and a first assessment
within **7 days**. If you have not heard back after that, please write again —
a lost mail should not turn into silence.

This is a one-person project. Please allow a reasonable time to fix an issue
before publishing details. 90 days is the usual convention; if a fix takes
longer, we will say so and explain why.

## Scope

Culpeo Studio runs on your own machine, so the interesting areas are:

- **File tools:** assistants can read and modify files inside a project
  folder. Anything that escapes that folder without the explicit approval
  prompt is a vulnerability.
- **Command execution:** `run_command` runs inside the project root without a
  shell. Report anything that circumvents that boundary.
- **Credentials:** provider API keys and the session signing secret live under
  `backend/data/`. Any path that exposes them — through the API, logs or error
  messages — is in scope.
- **Authentication:** everything around login, TOTP and session tokens.

Out of scope: findings that require an attacker to already have local access
to your user account, and issues in third-party runtimes (llama.cpp) — please
report those to the respective projects.

## Supported versions

The project is in alpha. Only the current `main` branch receives fixes;
there are no backports to older releases yet.

## Known limitations

Deliberate design decisions rather than bugs — reports about these are not
needed:

- Binding to a network interface via `HTTP_HOST=0.0.0.0` exposes the API to
  the local network. The default is `127.0.0.1` for that reason.
- Anyone with access to your user account can read `backend/data/`. The
  application does not protect against a compromised local account.
