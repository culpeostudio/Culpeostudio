# Contributing to PhiloEngine

**English** · [Deutsch](de/CONTRIBUTING.md)

Thank you for helping improve PhiloEngine. Bug fixes, hardware compatibility
reports, focused feature work, tests, documentation, and translations are all
valuable—especially while the project is in alpha.

[← README](README.md) · [Development](docs/DEVELOPMENT.md) · [Roadmap](ROADMAP.md)

## Before you begin

- Search the existing repository issues before opening a duplicate.
- For a substantial change, describe the problem and intended scope before
  investing in a large implementation.
- Keep pull requests focused. Unrelated refactors make review and regression
  testing harder.
- Never include credentials, `backend/data/`, model weights, private chat
  content, or unredacted local paths in a commit or issue.

Security vulnerabilities must not be reported in a public issue. Follow the
private process in the [security policy](https://github.com/kuchenboss/MyPhiloEngine/blob/main/SECURITY.md).

## Contributor agreement and sign-off

All contributions are subject to the [Contributor License Agreement](https://github.com/kuchenboss/MyPhiloEngine/blob/main/CLA.md).
Read the current agreement at that link before contributing. Include the
following exact confirmation from the current CLA in your pull request (the
German wording is intentional):

```text
Ich habe CLA.md gelesen und stimme den Bedingungen zu.
```

You retain copyright in your contribution while granting the rights described
in that project-specific CLA.

Every commit must separately carry a sign-off under the
[Developer Certificate of Origin 1.1](https://developercertificate.org/). Read
the DCO before signing off, then create signed-off commits with:

```bash
git commit -s
```

This adds a `Signed-off-by` trailer using your configured Git name and email.
The two requirements are not interchangeable: the CLA grants the
project-specific licence rights described in `CLA.md`, while the DCO sign-off
certifies the contribution's provenance and your right to submit it. A
`Signed-off-by` trailer does not by itself accept the CLA, and the pull-request
CLA confirmation does not replace the DCO sign-off.

## Development workflow

1. Fork the repository and create a branch for one coherent change.
2. Read the surrounding code and tests before editing.
3. Implement the smallest complete change that solves the problem.
4. Add or update tests for behavior that changed.
5. Update user-facing documentation and both UI languages where applicable.
6. Run the relevant verification commands.
7. Review the diff for secrets, generated output, unrelated formatting, and
   accidental local data.
8. Open a pull request that explains the problem, the solution, and how it was
   verified.

The [development guide](docs/DEVELOPMENT.md) contains setup, architecture, and
build details.

### AI-assisted contributions

AI-assisted tools are allowed, but their output is treated as a proposal. The
contributor remains responsible for understanding the change, reviewing the
diff, verifying tests, checking licences and provenance, and disclosing any
material limitation relevant to review. Do not submit generated code or text
that you cannot explain and maintain. The project's own approach is documented
in [Project transparency](docs/TRANSPARENCY.md).

## Verification

Run the checks that match your change. A cross-cutting change should run all
affected suites.

### Backend changes

```bash
cd backend
go test ./...
go build ./cmd/server
```

Changes to the updater should also build its command:

```bash
cd backend
go build ./cmd/philo-updater
```

### Frontend changes

```bash
cd frontend
flutter analyze
flutter test
```

For a user flow that depends on the real desktop application, run the relevant
integration test on a supported desktop target:

```bash
cd frontend
flutter test integration_test/ -d linux
```

### Python or release-tooling changes

From the repository root:

```bash
python3 -m unittest discover -s backend/engineworker -p 'test_*.py' -v
python3 -m unittest discover -s quikinstall/tests -v
```

Compile changed Python entry points with `python3 -m py_compile` as a minimum
syntax check.

### Documentation changes

- Confirm that every relative link resolves from the file containing it.
- Verify images and tables at normal GitHub width, not only in a wide editor.
- Use accessible alt text that describes the useful content of an image.
- Avoid hard-coded statistics or release numbers that will become stale.
- Keep commands copyable and state their working directory.

If a check cannot run on your system, say which check was skipped and why in
the pull request. Do not report an unrun check as passing.

## Code expectations

- Preserve Go and Dart type safety and return actionable errors.
- Do not swallow failures or replace a root cause with a generic success state.
- Keep network and filesystem operations bounded and validate untrusted input.
- Keep secrets out of logs, API responses, fixtures, and process arguments
  wherever the underlying runtime permits.
- Keep Flutter state and business logic out of presentation-only widgets.
- Use localized strings for user-facing text in both German and English.
- Use adaptive PhiloGrid layouts rather than hard-coded desktop widths.
- Add a regression test when fixing a reproducible bug.

## Pull request checklist

- [ ] The change has one clear purpose.
- [ ] Relevant tests were added or updated.
- [ ] Relevant local checks pass, or skipped checks are disclosed.
- [ ] User-facing text is available in German and English.
- [ ] Documentation reflects changed behavior.
- [ ] No credentials, runtime data, build output, or model files are included.
- [ ] Every commit includes a `Signed-off-by` trailer.
- [ ] The pull request contains the required CLA confirmation.

## Security-sensitive changes

Changes involving authentication, TOTP, session tokens, provider keys,
assistant tools, command execution, model remote code, update verification, or
archive extraction deserve explicit threat-boundary tests. Preserve the
loopback-only defaults and fail closed when an authorization decision is
missing or ambiguous.

For a vulnerability in the current code, stop the public contribution workflow
and use the [security policy](https://github.com/kuchenboss/MyPhiloEngine/blob/main/SECURITY.md) instead.

## License and project names

Contributions accepted into this repository are published under the project's
[GNU AGPL-3.0 license](https://github.com/kuchenboss/MyPhiloEngine/blob/main/LICENSE) and the terms of the CLA. The source-code
license does not grant rights to present a modified distribution as an official
PhiloEngine product. See the [trademark policy](https://github.com/kuchenboss/MyPhiloEngine/blob/main/TRADEMARK.md) for the naming policy.
