/**
 * yourpartsmap-proxy — Cloudflare Worker
 *
 * Proxies POST requests to the Anthropic API, adding CORS headers
 * so the app can call Claude directly from the browser.
 *
 * Secret required: ANTHROPIC_API_KEY (set via `wrangler secret put`)
 */

const CORS = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

export default {
  async fetch(request, env) {
    // CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS });
    }

    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405, headers: CORS });
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json', ...CORS },
      });
    }

    // Forward to Anthropic
    let upstream;
    try {
      upstream = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'x-api-key':           env.ANTHROPIC_API_KEY,
          'anthropic-version':   '2023-06-01',
          'content-type':        'application/json',
        },
        body: JSON.stringify(body),
      });
    } catch (e) {
      return new Response(JSON.stringify({ error: 'Upstream fetch failed: ' + e.message }), {
        status: 502,
        headers: { 'Content-Type': 'application/json', ...CORS },
      });
    }

    const data = await upstream.text();
    return new Response(data, {
      status: upstream.status,
      headers: {
        'Content-Type': 'application/json',
        ...CORS,
      },
    });
  },
};
