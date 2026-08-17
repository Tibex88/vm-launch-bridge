const http = require('http')
const crypto = require('crypto')

const PORT = 12345

const server = http.createServer((req, res) => {
  res.writeHead(426, { 'Content-Type': 'text/plain' })
  res.end('Expected WebSocket upgrade request\n')
})

server.on('upgrade', (req, socket) => {
  const key = req.headers['sec-websocket-key']

  if (!key) {
    socket.write('HTTP/1.1 400 Bad Request\r\n\r\n')
    socket.destroy()
    return
  }

  const acceptKey = crypto
    .createHash('sha1')
    .update(key + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11')
    .digest('base64')

  socket.write(
    [
      'HTTP/1.1 101 Switching Protocols',
      'Upgrade: websocket',
      'Connection: Upgrade',
      `Sec-WebSocket-Accept: ${acceptKey}`,
      '\r\n',
    ].join('\r\n')
  )

  console.log('WebSocket client connected')

  socket.on('data', (buffer) => {
    try {
      const firstByte = buffer[0]
      const opcode = firstByte & 0x0f

      if (opcode === 0x8) {
        console.log('WebSocket client requested close')
        socket.end()
        return
      }

      const secondByte = buffer[1]
      const isMasked = (secondByte & 0x80) === 0x80
      let payloadLength = secondByte & 0x7f
      let offset = 2

      if (payloadLength === 126) {
        payloadLength = buffer.readUInt16BE(offset)
        offset += 2
      } else if (payloadLength === 127) {
        payloadLength = Number(buffer.readBigUInt64BE(offset))
        offset += 8
      }

      let payload = buffer.subarray(offset, offset + payloadLength)

      if (isMasked) {
        const mask = buffer.subarray(offset, offset + 4)
        offset += 4
        payload = buffer.subarray(offset, offset + payloadLength)
        for (let i = 0; i < payload.length; i += 1) {
          payload[i] ^= mask[i % 4]
        }
      }

      const message = payload.toString('utf8')
      console.log('Received WS payload:')
      console.log(message)

      const reply = Buffer.from('AUTH_OK', 'utf8')
      const header =
        reply.length < 126
          ? Buffer.from([0x81, reply.length])
          : Buffer.from([0x81, 126, (reply.length >> 8) & 0xff, reply.length & 0xff])

      socket.write(Buffer.concat([header, reply]))
      console.log('Sent AUTH_OK')
    } catch (error) {
      console.error(error)
      socket.destroy()
    }
  })

  socket.on('error', (error) => {
    console.error(error)
  })
})

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Mock WebSocket server listening on ws://0.0.0.0:${PORT}/`)
})
