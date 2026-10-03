// Proxy setup: Decodo (custom proxy URLs) first, Apify Proxy / custom URLs from the input as fallback.
// Credentials are never logged: everything printed goes through redactProxyUrl() / scrubSecrets().
import { Actor, log } from 'apify';
import { gotScraping } from 'got-scraping';

/** "http://user:pass@host:port" -> "http://us***:***@host:port" */
export function redactProxyUrl(proxyUrl) {
    try {
        const u = new URL(proxyUrl);
        const user = u.username ? `${decodeURIComponent(u.username).slice(0, 2)}***` : '';
        const auth = user || u.password ? `${user}:***@` : '';
        return `${u.protocol}//${auth}${u.host}`;
    } catch {
        return '<unparseable proxy url>';
    }
}

/** Removes every secret (raw and URL-encoded) from a string, e.g. an upstream error message. */
export function scrubSecrets(text, secrets) {
    let out = String(text ?? '');
    for (const s of secrets.filter((x) => x && x.length >= 3)) {
        for (const variant of new Set([s, encodeURIComponent(s)])) out = out.split(variant).join('***');
    }
    return out;
}

function decodoCredentials(input) {
    return {
        username: input.decodoUsername || process.env.DECODO_USER || '',
        password: input.decodoPassword || process.env.DECODO_PASS || '',
        // Gateway "host:port". UNVERIFIED default: confirm the endpoint in the Decodo dashboard.
        host: input.decodoHost || process.env.DECODO_HOST || '',
    };
}

/** Every credential that must never appear in logs / errors (Decodo user+pass, custom proxy URL passwords). */
export function collectSecrets(input) {
    const decodo = decodoCredentials(input);
    const pc = input.proxyConfiguration ?? {};
    return [decodo.password, decodo.username, ...(pc.proxyUrls ?? []).map((u) => safePassword(u))];
}

// Wraps Actor.createProxyConfiguration: its validation errors echo the full proxy URL, password included
// (e.g. `Expected property string values to be a URL, got \`http://user:pass@bad host:1\``).
async function configureProxy(options) {
    try {
        return await Actor.createProxyConfiguration(options);
    } catch (err) {
        if (!options.proxyUrls?.length) throw err;
        throw new Error(`Invalid proxy URL(s): ${options.proxyUrls.map(redactProxyUrl).join(', ')}. Expected http://user:pass@host:port.`);
    }
}

/**
 * Returns { proxyConfiguration, label, secrets }.
 * proxyConfiguration is undefined when running without a proxy.
 */
export async function createProxy(input) {
    const decodo = decodoCredentials(input);
    const hasDecodo = Boolean(decodo.username && decodo.password && decodo.host);
    const pc = input.proxyConfiguration ?? {};
    const secrets = collectSecrets(input);

    let provider = input.proxyProvider;
    if (provider === 'auto') {
        if (hasDecodo) provider = 'decodo';
        else if (pc.proxyUrls?.length) provider = 'custom';
        else if (pc.useApifyProxy) provider = 'apify';
        else provider = 'none';
    }

    if (provider === 'decodo') {
        if (!hasDecodo) {
            throw new Error('proxyProvider is "decodo" but DECODO_USER / DECODO_PASS / DECODO_HOST (or the input fields) are not all set.');
        }
        if (!/^[^\s/:@]+:\d{1,5}$/.test(decodo.host)) {
            throw new Error('DECODO_HOST (or decodoHost) must be "host:port" without a scheme or path, e.g. gate.example:7000.');
        }
        const proxyUrl = `http://${encodeURIComponent(decodo.username)}:${encodeURIComponent(decodo.password)}@${decodo.host}`;
        // BUILDER: for sticky sessions, Decodo encodes the session in the username. If the source needs
        // one IP per crawlee session, replace proxyUrls with:
        //   newUrlFunction: (sessionId) => `http://${user}-session-${sessionId}:${pass}@${host}`
        // UNVERIFIED: check the exact username syntax in Decodo's docs before relying on it.
        const proxyConfiguration = await configureProxy({ proxyUrls: [proxyUrl] });
        return { proxyConfiguration, label: `Decodo ${redactProxyUrl(proxyUrl)}`, secrets };
    }

    if (provider === 'custom') {
        if (!pc.proxyUrls?.length) throw new Error('proxyProvider is "custom" but proxyConfiguration.proxyUrls is empty.');
        const proxyConfiguration = await configureProxy({ proxyUrls: pc.proxyUrls });
        return { proxyConfiguration, label: `custom ${pc.proxyUrls.map(redactProxyUrl).join(', ')}`, secrets };
    }

    if (provider === 'apify') {
        // Actor.createProxyConfiguration returns undefined if Apify Proxy is unavailable (e.g. locally without a token).
        const proxyConfiguration = await Actor.createProxyConfiguration({ ...pc, useApifyProxy: true });
        const groups = pc.apifyProxyGroups?.join('+') || 'auto';
        return { proxyConfiguration, label: `Apify Proxy (${groups})`, secrets };
    }

    return { proxyConfiguration: undefined, label: 'no proxy', secrets };
}

function safePassword(proxyUrl) {
    try {
        return decodeURIComponent(new URL(proxyUrl).password);
    } catch {
        return '';
    }
}

/**
 * Requests an IP-echo URL through the proxy. Logs exit IP + latency, throws a clear (redacted) error if unhealthy.
 */
export async function proxyHealthCheck({ proxyConfiguration, label, secrets }, url, timeoutMs = 20_000) {
    if (!proxyConfiguration) {
        log.info('Proxy health check skipped: running without a proxy.');
        return null;
    }
    const proxyUrl = await proxyConfiguration.newUrl(`health_${Date.now()}`);
    const started = Date.now();
    try {
        const res = await gotScraping({
            url,
            proxyUrl,
            timeout: { request: timeoutMs },
            retry: { limit: 1 },
            throwHttpErrors: false,
            useHeaderGenerator: false,
        });
        const latencyMs = Date.now() - started;
        if (res.statusCode >= 400) throw new Error(`HTTP ${res.statusCode} from ${url}`);
        const ip = parseIp(res.body);
        log.info(`Proxy health check OK via ${label}: exit IP ${ip ?? '(unparsed)'}, latency ${latencyMs} ms`);
        return { ip, latencyMs };
    } catch (err) {
        const msg = scrubSecrets(err?.message ?? err, secrets);
        throw new Error(`Proxy health check failed via ${label} (${url}): ${msg}. Check proxy credentials/host, or set skipProxyHealthCheck.`);
    }
}

function parseIp(body) {
    const text = String(body ?? '').trim();
    try {
        const j = JSON.parse(text);
        return j.ip ?? j.origin ?? j.query ?? j.proxy?.ip ?? null;
    } catch {
        return text.match(/\b\d{1,3}(?:\.\d{1,3}){3}\b|[0-9a-f:]{6,}/i)?.[0] ?? null;
    }
}
