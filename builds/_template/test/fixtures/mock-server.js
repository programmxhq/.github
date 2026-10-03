// Offline mock of a target site: JSON listing API + HTML detail pages + block/challenge pages.
// Dataset "version" can be switched between runs to simulate the source changing over time.
import http from 'node:http';

const CATALOG = {
    1: [
        { id: '1', title: 'Alpha', price: 10, updatedAt: '2026-09-01T00:00:00.000Z' },
        { id: '2', title: 'Bravo', price: 20, updatedAt: '2026-09-02T00:00:00.000Z' },
        { id: '3', title: 'Charlie', price: 30, updatedAt: '2026-09-03T00:00:00.000Z' },
        { id: '4', title: 'Delta', price: 40, updatedAt: '2026-09-04T00:00:00.000Z' },
        { id: '5', title: 'Echo', price: 50, updatedAt: '2026-09-05T00:00:00.000Z' },
        { id: '6', title: 'Foxtrot', price: 60, updatedAt: '2026-09-06T00:00:00.000Z' },
    ],
};
// v2: item 2 price changed, item 7 added, everything else identical.
CATALOG[2] = [
    ...CATALOG[1].map((it) => (it.id === '2' ? { ...it, price: 25, updatedAt: '2026-10-02T00:00:00.000Z' } : it)),
    { id: '7', title: 'Golf', price: 70, updatedAt: '2026-10-02T00:00:00.000Z' },
];

const PAGE_SIZE = 3;
const HARD_BLOCK_ONCE = new Set(['3']); // first request -> 403 challenge page
const SOFT_BLOCK_ONCE = new Set(['5']); // first request -> 200 captcha page

const CHALLENGE_HTML = `<!doctype html><html><head><title>Just a moment...</title></head>
<body><form id="challenge-form"></form><p>Checking your browser before accessing the site.</p></body></html>`;
const CAPTCHA_HTML = `<!doctype html><html><head><title>Verification</title></head>
<body><div class="g-recaptcha" data-sitekey="x"></div><p>Please verify you are human (captcha).</p></body></html>`;

export async function startMockServer() {
    const state = { version: 1, hits: {} };
    const server = http.createServer((req, res) => {
        const url = new URL(req.url, 'http://localhost');
        const key = url.pathname;
        state.hits[key] = (state.hits[key] ?? 0) + 1;
        const items = CATALOG[state.version];

        if (key === '/ip') {
            const ip = req.headers['x-stub-proxy-exit'] ?? req.socket.remoteAddress;
            return send(res, 200, 'application/json', JSON.stringify({ ip }));
        }
        if (key === '/api/items') {
            const page = Number(url.searchParams.get('page') ?? 1);
            const slice = items.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);
            const nextPage = page * PAGE_SIZE < items.length ? page + 1 : null;
            return send(res, 200, 'application/json', JSON.stringify({ items: slice.map((i) => ({ id: i.id, url: `/item/${i.id}` })), nextPage }));
        }
        const m = key.match(/^\/item\/([^/]+)$/);
        if (m) {
            const id = decodeURIComponent(m[1]);
            const item = items.find((i) => i.id === id);
            if (!item) return send(res, 404, 'text/html', '<html><head><title>Not found</title></head><body>404</body></html>');
            if (HARD_BLOCK_ONCE.has(id) && state.hits[key] === 1) return send(res, 403, 'text/html', CHALLENGE_HTML);
            if (SOFT_BLOCK_ONCE.has(id) && state.hits[key] === 1) return send(res, 200, 'text/html', CAPTCHA_HTML);
            return send(
                res,
                200,
                'text/html; charset=utf-8',
                `<!doctype html><html><head><title>${item.title} | Mock shop</title></head><body>
<article data-id="${item.id}"><h1 class="title">${item.title}</h1>
<span class="price" data-currency="USD">$${item.price.toFixed(2)}</span>
<time class="updated" datetime="${item.updatedAt}">${item.updatedAt.slice(0, 10)}</time></article></body></html>`,
            );
        }
        return send(res, 404, 'text/plain', 'not found');
    });
    await new Promise((r) => server.listen(0, '127.0.0.1', r));
    const { port } = server.address();
    return {
        url: `http://127.0.0.1:${port}`,
        state,
        resetHits: () => {
            state.hits = {};
        },
        close: () => new Promise((r) => server.close(r)),
    };
}

function send(res, status, type, body) {
    res.writeHead(status, { 'content-type': type, 'content-length': Buffer.byteLength(body) });
    res.end(body);
}
