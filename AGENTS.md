# Integration guidance

- Keep the relay bound to `127.0.0.1:4001`; do not expose it with `0.0.0.0` for a website integration.
- Prefer calling `POST http://127.0.0.1:4001/api/send` from the consuming app's backend. Add its stable client ID and SMTP settings to `clients.yaml`; keep credentials out of the app.
- The backend must validate input and constrain `client_id` and recipients. Protect its public endpoint with the controls appropriate to its auth/session model, including CSRF for cookie-based flows and rate limiting.
- A static frontend may use a same-origin Nginx route to the relay, but that route is public even while the relay port remains loopback-only. Restrict what it can send.
- Never call the relay's loopback URL from a visitor's browser: it resolves on the visitor's device. Never assume loopback binding makes a reverse-proxied endpoint private.
- Keep `README.md` and `README.es.md` aligned when updating integration guidance.
