// Tiny authenticating forward proxy (HTTP absolute-URI requests + CONNECT tunnels) for offline tests.
// Stands in for the Decodo gateway: requires Basic Proxy-Authorization and tags forwarded requests with
// an "exit IP" header so the mock /ip endpoint can echo it.
import http from 'node:http';
import net from 'node:net';

export const STUB_EXIT_IP = '203.0.113.7'; // TEST-NET-3, never routable

export async function startProxyStub({ username, password }) {
    const expected = `Basic ${Buffer.from(`${username}:${password}`).toString('base64')}`;
    const stats = { requests: 0, connects: 0, rejected: 0 };
    const authorized = (req) => req.headers['proxy-authorization'] === expected;

    const server = http.createServer((req, res) => {
        if (!authorized(req)) {
            stats.rejected++;
            res.writeHead(407, { 'proxy-authenticate': 'Basic realm="stub"' });
            return res.end();
        }
        stats.requests++;
        const target = new URL(req.url);
        const headers = { ...req.headers, 'x-stub-proxy-exit': STUB_EXIT_IP };
        delete headers['proxy-authorization'];
        delete headers['proxy-connection'];
        const upstream = http.request(
            { host: target.hostname, port: target.port || 80, path: target.pathname + target.search, method: req.method, headers },
            (up) => {
                res.writeHead(up.statusCode, up.headers);
                up.pipe(res);
            },
        );
        upstream.on('error', () => {
            res.writeHead(502);
            res.end();
        });
        req.pipe(upstream);
    });

    server.on('connect', (req, socket, head) => {
        if (!authorized(req)) {
            stats.rejected++;
            socket.end('HTTP/1.1 407 Proxy Authentication Required\r\n\r\n');
            return;
        }
        stats.connects++;
        const [host, port] = req.url.split(':');
        const upstream = net.connect(Number(port), host, () => {
            socket.write('HTTP/1.1 200 Connection Established\r\n\r\n');
            upstream.write(head);
            upstream.pipe(socket);
            socket.pipe(upstream);
        });
        upstream.on('error', () => socket.destroy());
        socket.on('error', () => upstream.destroy());
    });

    await new Promise((r) => server.listen(0, '127.0.0.1', r));
    return {
        host: `127.0.0.1:${server.address().port}`,
        stats,
        close: () => new Promise((r) => {
            server.closeAllConnections?.();
            server.close(r);
        }),
    };
}
