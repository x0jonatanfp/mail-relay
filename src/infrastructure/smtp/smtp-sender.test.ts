import { describe, it, expect, vi } from 'vitest'

const sendMail = vi.fn(async () => ({}))
vi.mock('nodemailer', () => ({ default: { createTransport: vi.fn(() => ({ sendMail })) } }))

const { SmtpSender } = await import('./smtp-sender.js')

const client = {
  id: 'acme',
  name: 'Acme',
  domains: ['acme.test'],
  smtp: { host: 'smtp.acme.test', port: 465, secure: true, user: 'u', pass: 'p' },
  from: { name: 'Acme', email: 'web@acme.test' },
  to: 'info@acme.test',
}

describe('SmtpSender', () => {
  it('envía siempre al destinatario configurado del cliente', async () => {
    // Un `to` colado en los datos (cliente antiguo o petición manipulada) no debe cambiar el destino.
    const data = { client_id: 'acme', to: 'victima@example.com', from_name: 'A', from_email: 'a@example.com', subject: 's', message: 'm' }

    const result = await new SmtpSender().send(data as never, client)

    expect(result.success).toBe(true)
    expect(sendMail).toHaveBeenCalledWith(expect.objectContaining({ to: 'info@acme.test' }))
  })
})
