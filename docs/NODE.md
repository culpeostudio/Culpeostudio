# Running Culpeo Studio models on a server

A **node** is another machine this Studio may download models to and run them
on. It is not a separate program: it is the same Go backend, started headless
with `CULPEO_NODE_MODE=1` and reached over a WireGuard tunnel.

Two properties follow, and both are the point of the feature:

- A download aimed at a node is fetched **by the node**, straight from the
  model host. The weights never cross the tunnel.
- A model started on a node appears beside the local ones in the engine and in
  the chat model picker. Only the process is elsewhere; its output is streamed
  back through the node's OpenAI gateway.

A node needs no Flutter, no desktop session and no display — only Go to build
the backend, and WireGuard for the tunnel.

---

## 1. Install the node on the server

The server side has its own project — **culpeo-node** — which carries the
installer, the systemd service and the tunnel setup. It holds no backend code:
it fetches this repository at a pinned revision and builds only
`backend/cmd/server` from it. Two copies of the same backend would drift apart,
and then a server would be running something other than the Studio.

```bash
git clone <culpeo-node> culpeo-node
cd culpeo-node
sudo ./install.sh --endpoint node.example.org:51820 --name "Workshop"
```

That installer:

1. checks that Go, Git and `wireguard-tools` are present,
2. fetches this repository (`--ref` pins a branch, tag or commit) and builds
   **only** the backend — no Flutter involved,
3. creates the `culpeo` service account and `/opt/culpeo-node`,
4. runs the node once in setup mode, which creates its identity, writes the
   tunnel config and prints the join code,
5. installs the tunnel as `wg-quick@<interface>` and enables it,
6. installs and starts the `culpeo-node` systemd service.

The rest of this document describes what a node *is* and how the Studio talks
to it. For the installer's options, see that project's own documentation.

### Running a node straight from this checkout

For development it is enough to start the backend with the node settings, on a
machine whose tunnel is already up:

```bash
cd backend
CULPEO_NODE_MODE=1 CULPEO_NODE_WG_ENDPOINT=node.example.org:51820 go run ./cmd/server
```

The first run only sets up — see below.

### Why a setup run rather than one start

A node binds its control plane to its own address **inside** the tunnel, and
that tunnel is described by a config the node itself writes on first start.
The very first run therefore cannot serve anything — the interface does not
exist yet. `CULPEO_NODE_INIT=1` does the setup, prints the join code and exits;
the tunnel is brought up afterwards, and only then is the service started.

The systemd unit records that dependency (`Requires=wg-quick@<interface>`), and
a node whose control plane fails to bind stops rather than lingering as a
process that is running but unreachable.

---

## 2. Add the node in the Studio

**Settings → Nodes → Add node**, paste the join code.

The Studio writes its side of the tunnel to `data/wireguard/<interface>.conf`
(mode 0600) and shows what is still missing — almost always the tunnel itself.
**Bring tunnel up** runs `wg-quick` behind a privilege prompt:

- **Linux:** via `pkexec`. Without it, the Studio shows the command to copy.
- **Windows and macOS:** the command is shown only. A desktop app that quietly
  takes administrator rights would be worse than one that asks.

Then press **Refresh**. The node reports its hardware, free disk, model and
instance counts, and issues the Studio a gateway key for inference.

### Without a public address

If `CULPEO_NODE_WG_ENDPOINT` is unset, no tunnel is built and no join code is
printed — a public address cannot be guessed. The node still works if you run
your own tunnel: identity and token are created regardless and reported in the
log, and in the Studio you switch the add dialog to the manual form and enter
address, token and ports. The Studio then writes no config and touches no
interface.

---

## 3. Security

**The pairing token is not a login.** It reaches the engine and marketplace
calls and nothing else. Memory, scouts, chats, accounts and the node's own
gateway keys stay out of its range. A token that leaks can load and start
models; it cannot read what is on the machine.

**The join code contains the Studio's private key.** This is deliberate and
unavoidable: a Studio cannot announce a public key over a tunnel it is trying
to establish with that very announcement, and a node behind NAT cannot be told
one afterwards. So the node generates both key pairs and hands one over. Treat
a join code exactly like a WireGuard config file.

**The link is unencrypted inside the tunnel.** WireGuard already authenticates
both ends by key and encrypts everything between them; TLS on top would be a
second certificate story for a path that is not reachable from anywhere else.
The Studio therefore refuses to send a pairing token to a public address.

---

## 4. Limits

- **Quantizing, presets and runtime installation stay local.** Quantizing
  writes a file next to another, on the machine that holds it. A model on a
  node is refused with a clear message.
- **No chains of nodes.** A node does not forward to further nodes; otherwise
  the topology is a graph and every list is a question about cycles.
- **One Studio per node.** The tunnel network is laid out for two addresses.
- **Node events are polled, not pushed.** While an engine screen is open the
  Studio asks every five seconds; after that it goes quiet. A node cannot open
  a connection into the Studio, because the tunnel is dialed from there.
- **A node that does not answer drops out of the lists — it does not empty
  them.** Only a reachable node reporting that something is gone produces a
  deletion.

---

## 5. Operating it

```bash
systemctl status culpeo-node
journalctl -u culpeo-node -f
systemctl status wg-quick@culpeo-<id>
```

| Studio shows | What is going on |
|---|---|
| **Not reachable** | Tunnel is down, or no backend is running on the node. Check `sudo wg show` on both sides |
| **Token rejected** | The node got a new identity (e.g. `data/node_identity.json` was deleted). Remove the node in the Studio and add it again with the new join code |
| **WireGuard missing** | `wireguard-tools` is not installed on the Studio machine. The config can be written, but nothing can be said about the interface |
| **Managed elsewhere** | The node was added manually. The Studio does not control that tunnel, by design |
| Model starts, chat says no gateway access | The node could not bind its gateway to the tunnel address. Refresh the node to fetch the key. If it persists, the node has no tunnel address — `CULPEO_NODE_WG_ENDPOINT` is missing |

Models land in `<install dir>/data/models`. That is the volume that needs the
space.
