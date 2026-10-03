// =====================================================================================
// SOURCE-SPECIFIC CODE. This is the only src/ file a builder normally needs to change.
// The example below scrapes the local mock catalog in test/fixtures/mock-server.js:
//   LIST   GET {BASE}/api/items?page=N  -> JSON { items: [{ id, url }], nextPage }
//   DETAIL GET {BASE}/item/:id          -> HTML page with title / price / updated date
// =====================================================================================
import { createCheerioRouter } from '@crawlee/cheerio';

// BUILDER: short kebab-case source name; names the persistent monitoring store "<SOURCE_NAME>-monitor".
export const SOURCE_NAME = 'example-source';

// BUILDER: hardcode the real site. The env override exists so tests can point at the mock server.
export const BASE_URL = process.env.SOURCE_BASE_URL ?? 'https://example.com';

// Fields that change on every run and must not count as a "change" in monitoring mode.
export const VOLATILE_FIELDS = ['scrapedAt', 'changeType'];

export const LABELS = { LIST: 'LIST', DETAIL: 'DETAIL' };

/** BUILDER: map input (start URLs and/or IDs) to the first requests. */
export function buildStartRequests(input) {
    const fromUrls = input.startUrls.map((s) => ({ url: s.url ?? s, label: LABELS.LIST }));
    const fromIds = input.ids.map((id) => ({ url: detailUrl(id), label: LABELS.DETAIL, userData: { id } }));
    return [...fromUrls, ...fromIds];
}

const detailUrl = (id) => new URL(`/item/${encodeURIComponent(id)}`, BASE_URL).href;

/** BUILDER: return the record's "last updated" Date (used by the `since` filter), or null if unknown. */
export function getRecordDate(record) {
    return record.updatedAt ? new Date(record.updatedAt) : null;
}

/**
 * Block / challenge detection for responses that came back 200 but are not real content.
 * (401/403/429 status codes are already treated as blocked by crawlee's session pool.)
 * Return a short reason string to retire the session and retry, or null if the page is fine.
 * BUILDER: add the source's own markers (empty JSON, login wall, "unusual traffic" text...).
 */
export function detectBlock({ $, body }) {
    const text = typeof body === 'string' ? body : (body?.toString?.() ?? '');
    if ($) {
        const title = $('title').text().toLowerCase();
        if (/just a moment|attention required|access denied|are you a robot/.test(title)) return `challenge title "${title}"`;
        if ($('#challenge-form, #cf-challenge-running, .g-recaptcha, .h-captcha, [data-sitekey]').length) return 'captcha element';
    }
    if (text.length < 5000 && /captcha|verify you are human/i.test(text)) return 'captcha text';
    return null;
}

/** Route handlers. `sink.add(record)` saves + charges; never call pushData directly. */
export function createRouter({ sink }) {
    const router = createCheerioRouter();

    router.addHandler(LABELS.LIST, async ({ request, json, body, crawler, log }) => {
        const data = json ?? JSON.parse(body.toString());
        log.info(`LIST ${request.url}: ${data.items.length} items`);
        if (sink.stopped) return;
        await crawler.addRequests(
            data.items.map((it) => ({
                url: new URL(it.url, request.loadedUrl ?? request.url).href,
                label: LABELS.DETAIL,
                userData: { id: String(it.id) },
            })),
        );
        if (data.nextPage) {
            const next = new URL(request.url);
            next.searchParams.set('page', String(data.nextPage));
            await crawler.addRequests([{ url: next.href, label: LABELS.LIST }]);
        }
    });

    router.addHandler(LABELS.DETAIL, async ({ request, $ }) => {
        const priceText = $('.price').first().text().replace(/[^0-9.]/g, '');
        await sink.add({
            id: String(request.userData.id ?? $('[data-id]').attr('data-id')),
            url: request.loadedUrl ?? request.url,
            title: $('h1.title').text().trim(),
            price: priceText ? Number(priceText) : null,
            currency: $('.price').attr('data-currency') ?? null,
            updatedAt: $('time.updated').attr('datetime') ?? null,
        });
    });

    return router;
}
