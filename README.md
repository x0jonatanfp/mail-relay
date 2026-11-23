<div align="center">

# mail-relay

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Node Version](https://img.shields.io/badge/node-%3E%3D18-blue)]()
[![TypeScript](https://img.shields.io/badge/built_with-TypeScript-3178C6)]()

**Multi-client SMTP relay for web contact forms. One service, unlimited projects.**

</div>


---

<p align="center">🌐 <strong>Also available in:</strong> <a href="README.es.md">Spanish</a></p>

---
## Features

- **Multi-client** — Handle contact forms from multiple websites with a single service
- **YAML configuration** — Add a new client by copying one block
- **Secure SMTP** — Supports SSL/TLS (port 465) and STARTTLS (port 587)
- **PostgreSQL persistence** — Every submission is recorded with date, client, status, and error details
- **Telegram notifications** — Get detailed alerts when a form is submitted, error reports on failures, and periodic service status every 2 hours
- **Custom HTML templates** — Per-client email templates with variable injection
- **Production ready** — Includes a systemd unit template plus `make` targets to render, install and deploy it

---

## Quick start

### Prerequisites

- Node.js 18+
- pnpm
- PostgreSQL (running and accessible)

### Installation

```bash
git clone https://github.com/x0jonatanfp/mail-relay.git
cd mail-relay
pnpm install
```

### Configuration

Start by copying the example files:

```bash
cp clients.example.yaml clients.yaml
cp .env.example .env
```

Edit `clients.yaml` with your SMTP credentials:

```yaml
clients:
  - id: my-client
    name: My Client
    domains:
      - myclient.com
    smtp:
      host: smtp.myclient.com
      port: 587
      secure: false
      user: forms@myclient.com
      pass: "your-password"
    from:
      name: My Client
      email: no-reply@myclient.com
    to: info@myclient.com
    template: default
```

Create the database and configure `.env`:

```bash
createdb mailrelay
```

Then set your environment variables:

| Variable | Description |
|---|---|
| `PORT` | Server port (default: 4001) |
| `BIND` | Bind address (`127.0.0.1` or `0.0.0.0`) |
| `TELEGRAM_BOT_TOKEN` | Your Telegram bot token |
| `TELEGRAM_CHAT_ID` | Chat or group ID for notifications |
| `DATABASE_URL` | PostgreSQL connection string (`postgresql://user:pass@host:5432/mailrelay`) |

> **Note:** `clients.yaml` and `.env` are in `.gitignore` to prevent accidental commits of sensitive data.

The required database table is created automatically — or manually with:

```sql
CREATE TABLE sent_emails (
  id         SERIAL PRIMARY KEY,
  date       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  client_id  VARCHAR(100) NOT NULL,
  client_name VARCHAR(200) NOT NULL,
  to_email   VARCHAR(255) NOT NULL,
  subject    VARCHAR(255),
  status     VARCHAR(20) NOT NULL,
  error_msg  TEXT
);
```

---

## Usage

```bash
# Development
pnpm dev

# Production
pnpm build
pnpm serve
```

### API endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/health` | Service health check |
| `POST` | `/api/send` | Submit a contact form |

### Sending a form

```bash
curl -X POST http://localhost:4001/api/send \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": "my-client",
    "from_name": "John Doe",
    "from_email": "john@example.com",
    "message": "I would like more information about your products."
  }'
```

The message always goes to the client's `to` address in `clients.yaml`. A `to` field in the request is ignored, so a public form cannot be used to send mail to arbitrary recipients.

Response:

```json
{
  "success": true,
  "method": "smtp",
  "message": "Message sent successfully"
}
```

### Integrating another application

By default, the relay listens only on `127.0.0.1:4001`. This prevents direct connections to the port from another machine, but **does not** make routes private when a reverse proxy publishes them.

Recommended convention for a new application:

1. Add a client to `clients.yaml` with a stable `id`, domains, and SMTP/recipient settings. Do not copy credentials into the consuming application.
2. Have the application's **backend** send `POST http://127.0.0.1:4001/api/send` with `Content-Type: application/json` and a body like the example above. The backend should set the allowed `client_id` (the recipient always comes from `clients.yaml`); do not trust these values when freely supplied by the browser.
3. Validate and rate-limit requests at the application's public endpoint (authentication where appropriate, CSRF protection for cookie/session flows, and field validation). The backend should translate the relay result into its own API response.
4. If the frontend is static and has no backend, expose a same-origin route (for example, `/api/send`) through Nginx to `127.0.0.1:4001`. That route is public even though the relay port only listens on loopback: protect it and restrict the clients, fields, and recipients it accepts.

Do not call `127.0.0.1:4001` from the user's browser: `127.0.0.1` would refer to the user's device, not the server. Do not change `BIND` to `0.0.0.0` to integrate a website.

The `http://localhost:4001` address in the `curl` example is for testing from the same server where the relay runs. For development, use a local proxy or configure the backend to reach the relay over loopback on the same host.

---

## Telegram notifications

**Form received:**

```
📬 Nuevo formulario · My Client
━━━━━━━━━━━━━━━━━━
👤 John Doe
📧 john@example.com
📞 +1 234 567 890
📝 Product inquiry
```

**Error on send:**

```
❌ Error · My Client
━━━━━━━━━━━━━━━━━━
⚠️  Connection refused
🔧 smtp.myclient.com:587
```

**Periodic status (every 2h):**

```
📊 mail-relay · Status 14:30
━━━━━━━━━━━━━━━━━━
👥 Clientes:     3 activos
📬 Envíos hoy:   8
📈 Total acum.:  340
⏱  Último envío: hace 2 min
━━━━━━━━━━━━━━━━━━
```

---

## Deployment

The service runs as a **system systemd unit**. `deploy/mail-relay.service` is a
**template**: it is not copied verbatim, because its placeholders are filled in
at install time.

```bash
make install
```

`make install` renders the template, replacing `@DEPLOY_USER@`, `@DEPLOY_GROUP@`,
`@DEPLOY_HOME@`, `@DEST@` and `@NODE_BIN@`, installs the result as
`/etc/systemd/system/mail-relay.service` and reloads systemd. It does not enable
or start the unit: `make deploy` does that once the production secrets exist.

| Variable | Default |
|---|---|
| `DEST` | the destination directory set by the Makefile (override with `DEST=…`) |
| `DEPLOY_USER` | the user running `make` |
| `DEPLOY_GROUP` | their primary group |
| `DEPLOY_HOME` | their home directory |
| `NODE_BIN` | `node` from `PATH` (or `/usr/bin/node`) |

You can override them on the command line:

```bash
make install DEST=/opt/mail-relay DEPLOY_USER=relay
```

The template starts Node through a secrets launcher, which exports
`DATABASE_URL` and loads the service `.env`. If you do not use a launcher, change
`ExecStart` to call the Node binary directly and keep the `.env` in the working
directory. The unit writes `/var/log/mail-relay.log` (rotated by logrotate) and
keeps the journal (`journalctl -u mail-relay`).

To see the values that will be used before installing anything, `make -n install`
prints the commands with the substitutions resolved.

Build, sync the code and restart in one step:

```bash
make deploy
```

Manual install, if you prefer not to use the Makefile:

```bash
DEST=/opt/mail-relay  # the directory where the service lives
sed -e "s|@DEPLOY_USER@|$(id -un)|g" \
    -e "s|@DEPLOY_GROUP@|$(id -gn)|g" \
    -e "s|@DEPLOY_HOME@|$HOME|g" \
    -e "s|@DEST@|$DEST|g" \
    -e "s|@NODE_BIN@|$(command -v node)|g" \
    deploy/mail-relay.service > /tmp/mail-relay.service
sudo install -m 0644 /tmp/mail-relay.service /etc/systemd/system/mail-relay.service
sudo systemctl daemon-reload
sudo systemctl enable --now mail-relay.service
```

---

## Project structure

```
mail-relay/
├── src/
│   ├── application/services/   # Business logic
│   ├── config/                 # YAML, env, and DB config loaders
│   ├── domain/                 # Entities and ports
│   ├── infrastructure/
│   │   ├── http/               # Express server
│   │   ├── smtp/               # Nodemailer adapter
│   │   ├── telegram/           # Telegram notifications
│   │   └── persistence/        # PostgreSQL relay-store
│   └── index.ts                # Entry point
├── templates/                  # HTML email templates
├── clients.example.yaml        # Client configuration template
├── .env.example                # Environment variables template
├── deploy/mail-relay.service   # systemd unit template
├── Makefile                    # install + build + deploy + restart
└── LICENSE                     # MIT License
```

---

## Technology stack

| Component | Technology |
|---|---|
| Runtime | Node.js 18+ |
| Framework | Express |
| Email | Nodemailer |
| Database | PostgreSQL |
| Configuration | js-yaml + dotenv |
| Notifications | Telegram Bot API |
| Init system | systemd |
