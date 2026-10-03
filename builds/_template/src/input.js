// Input defaults + validation.
// The platform fills `default` values from .actor/input_schema.json, but local runs
// (`node src/main.js`, tests) do not, so every default is repeated here. Keep them in sync.

export const INPUT_DEFAULTS = {
    startUrls: [],
    ids: [],
    maxItems: 100,
    monitoringMode: 'all', // 'all' | 'new' | 'newOrChanged'
    monitoringKey: '',
    since: '',
    proxyProvider: 'auto', // 'auto' | 'decodo' | 'apify' | 'custom' | 'none'
    proxyConfiguration: { useApifyProxy: false },
    decodoUsername: '',
    decodoPassword: '',
    decodoHost: '',
    skipProxyHealthCheck: false,
    proxyHealthCheckUrl: 'https://api.ipify.org?format=json',
    maxRequestRetries: 5,
    backoffBaseMillis: 1000,
    maxConcurrency: 10,
    requestTimeoutSecs: 30,
    pushBatchSize: 20,
};

const MONITORING_MODES = new Set(['all', 'new', 'newOrChanged']);
const PROXY_PROVIDERS = new Set(['auto', 'decodo', 'apify', 'custom', 'none']);

/** Parses `since` ("YYYY-MM-DD", full ISO, or "7 days") into a Date, or null when empty. */
export function parseSince(since, now = new Date()) {
    if (!since) return null;
    const rel = String(since).trim().match(/^(\d+)\s*(hour|day|week|month|year)s?$/i);
    if (rel) {
        const n = Number(rel[1]);
        const d = new Date(now);
        const unit = rel[2].toLowerCase();
        if (unit === 'hour') d.setUTCHours(d.getUTCHours() - n);
        if (unit === 'day') d.setUTCDate(d.getUTCDate() - n);
        if (unit === 'week') d.setUTCDate(d.getUTCDate() - 7 * n);
        if (unit === 'month') d.setUTCMonth(d.getUTCMonth() - n);
        if (unit === 'year') d.setUTCFullYear(d.getUTCFullYear() - n);
        return d;
    }
    const abs = new Date(since);
    if (Number.isNaN(abs.getTime())) throw new Error(`Input "since" is not a date or relative period: ${since}`);
    return abs;
}

export function normalizeInput(raw) {
    const input = { ...INPUT_DEFAULTS, ...(raw ?? {}) };
    // Treat explicit nulls (nullable fields, API callers) as "use default".
    for (const [k, v] of Object.entries(INPUT_DEFAULTS)) if (input[k] === null || input[k] === undefined) input[k] = v;

    if (!MONITORING_MODES.has(input.monitoringMode)) throw new Error(`Invalid monitoringMode: ${input.monitoringMode}`);
    if (!PROXY_PROVIDERS.has(input.proxyProvider)) throw new Error(`Invalid proxyProvider: ${input.proxyProvider}`);
    if (!Array.isArray(input.startUrls) || !Array.isArray(input.ids)) throw new Error('startUrls and ids must be arrays');
    if (input.startUrls.length === 0 && input.ids.length === 0) {
        throw new Error('Provide at least one start URL or item ID.');
    }
    input.ids = input.ids.map((id) => String(id).trim()).filter(Boolean);
    input.sinceDate = parseSince(input.since);
    input.maxItems = Math.max(0, Number(input.maxItems) || 0);
    return input;
}
