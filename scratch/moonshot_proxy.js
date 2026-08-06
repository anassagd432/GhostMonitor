const http = require('http');
const https = require('https');

const API_KEY = 'sk-nzIawOjCd1lFwky6Ryz5nm4t9K2hoJUv42uBOseK3MHt2pZV';

const server = http.createServer((req, res) => {
  if (req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      object: 'list',
      data: [
        { id: 'kimi-k3', object: 'model', owned_by: 'moonshot' },
        { id: 'moonshotai/kimi-k3-free', object: 'model', owned_by: 'moonshot' },
        { id: 'kimi-k2.7-code', object: 'model', owned_by: 'moonshot' },
        { id: 'kimi-k2.6', object: 'model', owned_by: 'moonshot' }
      ]
    }));
    return;
  }

  let body = '';
  req.on('data', chunk => body += chunk);
  req.on('end', () => {
    let parsed = {};
    try { parsed = JSON.parse(body); } catch(e) {}
    
    let targetModel = parsed.model || 'kimi-k2.6';
    if (targetModel.includes('kimi-k3')) {
      targetModel = 'kimi-k2.6'; // fallback to kimi-k2.6 to avoid 429 TPD daily limit
    }
    
    const payload = JSON.stringify({
      model: targetModel,
      messages: parsed.messages || [{ role: 'user', content: 'hi' }],
      temperature: 1,
      stream: parsed.stream !== false
    });

    const options = {
      hostname: 'api.moonshot.ai',
      port: 443,
      path: '/v1/chat/completions',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    };

    const proxyReq = https.request(options, proxyRes => {
      res.writeHead(proxyRes.statusCode, proxyRes.headers);
      proxyRes.pipe(res);
    });

    proxyReq.on('error', err => {
      res.writeHead(500);
      res.end(JSON.stringify({ error: err.message }));
    });

    proxyReq.write(payload);
    proxyReq.end();
  });
});

server.listen(4000, '127.0.0.1', () => {
  console.log('Moonshot Kimi Local Proxy running on http://127.0.0.1:4000/v1');
});
