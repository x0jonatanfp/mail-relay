import { describe, it, expect, vi, beforeAll, afterAll } from 'vitest'
import { mkdtempSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import type { AddressInfo } from 'node:net'
import type { Server } from 'node:http'

process.env.LOG_FILE = join(mkdtempSync(join(tmpdir(), 'mail-relay-server-')), 'mail-relay.log')

vi.mock('../persistence/relay-store.js', () => ({
  getServiceStatus: vi.fn(async () => ({ clientCount: 1, todayCount: 1, totalSent: 1, errorsToday: 0 })),
  pingDatabase: vi.fn(async () => undefined),
}))

const { createServer } = await import('./server.js')
const { findClient } = await import('../../config/clients.js')

const client = {
  id: 'acme',
  name: 'Acme',
  domains: ['acme.test'],
  smtp: { host: 'smtp.acme.test', port: 465, secure: true, user: 'u', pass: 'p' },
  from: { name: 'Acme', email: 'web@acme.test' },
  to: 'info@acme.test',
}

const send = vi.fn(async () => ({ success: true, method: 'smtp' as const, message: 'ok' }))
const mailRelay = { send } as never
const telegram = { sendFormNotification: vi.fn(async () => {}), sendErrorNotification: vi.fn(async () => {}) } as never

let server: Server
let base: string

beforeAll(async () => {
  const clients = new Map([[client.id, client]])
  expect(findClient(clients, 'acme')).toBe(client)
  const app = createServer(mailRelay, clients, 1, telegram)
  server = app.listen(0, '127.0.0.1')
  await new Promise((resolve) => server.once('listening', resolve))
  base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`
})

afterAll(() => new Promise<void>((resolve) => server.close(() => resolve())))

describe('POST /api/send', () => {
  it('no deja elegir el destinatario: ignora el campo to del formulario', async () => {
    const res = await fetch(`${base}/api/send`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        client_id: 'acme',
        to: 'victima@example.com',
        from_name: 'Spammer',
        from_email: 'spam@example.com',
        message: 'hola',
      }),
    })

    expect(res.status).toBe(200)
    expect(send).toHaveBeenCalledTimes(1)
    const [formData] = send.mock.calls[0] as unknown as [Record<string, unknown>]
    expect(formData).not.toHaveProperty('to')
    expect(formData.extra).toBeUndefined()
  })

  it('sigue pasando los campos extra que no son estándar', async () => {
    send.mockClear()
    await fetch(`${base}/api/send`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ client_id: 'acme', from_name: 'A', from_email: 'a@example.com', message: 'm', company: 'X' }),
    })

    const [formData] = send.mock.calls[0] as unknown as [Record<string, unknown>]
    expect(formData.extra).toEqual({ company: 'X' })
  })
})
