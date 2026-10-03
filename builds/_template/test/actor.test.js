// End-to-end tests: run the real Actor (node src/main.js) offline against a local mock site and a
// local authenticating forward proxy that stands in for Decodo. Run with `npm test`.
import assert from 'node:assert/strict';
import { after, before, describe, test } from 'node:test';

import { fingerprint } from '../src/monitor.js';
import { parseSince } from '../src/input.js';
import { redactProxyUrl, scrubSecrets } from '../src/proxy.js';
import { startMockServer } from './fixtures/mock-server.js';
import { startProxyStub, STUB_EXIT_IP } from './fixtures/proxy-stub.js';
import { chargeTotals, cleanStorage, makeStorageDir, readDataset, readKv, runActor } from './helpers.js';

const PROXY_USER = 'decodo-test-user';
const PROXY_PASS = 'Sup3r-Secret-Pa55';
const PPE_ENV = { ACTOR_TEST_PAY_PER_EVENT: 'true', ACTOR_USE_CHARGING_LOG_DATASET: 'true' };

let mock;
let stub;
const ids = (items) => items.map((i) => i.id).sort();

cleanStorage(); // at load time, before describe() blocks create their dirs

before(async () => {
    mock = await startMockServer();
    stub = await startProxyStub({ username: PROXY_USER, password: PROXY_PASS });
});
after(async () => {
    await mock.close();
    await stub.close();
    cleanStorage();
});

function baseInput(extra = {}) {
    return {
        startUrls: [{ url: `${mock.url}/api/items?page=1` }],
        proxyHealthCheckUrl: `${mock.url}/ip`,
        backoffBaseMillis: 20,
        maxRequestRetries: 3,
        ...extra,
    };
}
const decodoEnv = (pass = PROXY_PASS) => ({ SOURCE_BASE_URL: mock.url, DECODO_USER: PROXY_USER, DECODO_PASS: pass, DECODO_HOST: stub.host });

describe('monitoring mode across two scheduled runs (via Decodo-style proxy, PPE simulated)', () => {
    const storageDir = makeStorageDir('monitor');
    let run1;

    test('run 1: saves every item, retries 403 + challenge page, charges once per item', async () => {
        mock.state.version = 1;
        mock.resetHits();
        const stubBefore = stub.stats.requests;
        run1 = await runActor({ storageDir, input: baseInput({ monitoringMode: 'newOrChanged' }), env: { ...decodoEnv(), ...PPE_ENV } });
        assert.equal(run1.code, 0, run1.output);

        const items = readDataset(storageDir);
        assert.deepEqual(ids(items), ['1', '2', '3', '4', '5', '6']);
        assert.ok(items.every((i) => i.changeType === 'new' && i.scrapedAt && i.url.includes('/item/')));
        assert.equal(items.find((i) => i.id === '2').price, 20);

        assert.equal(mock.state.hits['/item/3'], 2, '403 challenge page was retried once');
        assert.equal(mock.state.hits['/item/5'], 2, 'soft captcha page was detected and retried once');
        assert.match(run1.output, /Retry 1\/3 for .*\/item\/3/);

        assert.equal(chargeTotals(storageDir).result, 6, 'one "result" charge per saved item');
        assert.equal(readKv(storageDir, 'RUN_SUMMARY').saved, 6);

        assert.match(run1.output, new RegExp(`Proxy health check OK via Decodo .*exit IP ${STUB_EXIT_IP.replaceAll('.', '\\.')}, latency \\d+ ms`));
        assert.ok(stub.stats.requests - stubBefore >= 11, 'health check + all crawl requests went through the proxy');
        assert.ok(!run1.output.includes(PROXY_PASS), 'proxy password never printed');
    });

    test('run 2: source changed -> only the changed and the new item are saved and charged', async () => {
        mock.state.version = 2;
        mock.resetHits();
        const run2 = await runActor({ storageDir, input: baseInput({ monitoringMode: 'newOrChanged' }), env: { ...decodoEnv(), ...PPE_ENV } });
        assert.equal(run2.code, 0, run2.output);

        const items = readDataset(storageDir); // default dataset is purged at start of each local run
        assert.deepEqual(ids(items), ['2', '7']);
        assert.equal(items.find((i) => i.id === '2').changeType, 'changed');
        assert.equal(items.find((i) => i.id === '2').price, 25);
        assert.equal(items.find((i) => i.id === '7').changeType, 'new');
        assert.equal(chargeTotals(storageDir).result, 2, 'unchanged items are not charged');
        const summary = readKv(storageDir, 'RUN_SUMMARY');
        assert.equal(summary.skippedUnchanged, 5);
        assert.ok(!run2.output.includes(PROXY_PASS));
    });

    test('run 3: "new" mode with nothing new saves nothing', async () => {
        const run3 = await runActor({ storageDir, input: baseInput({ monitoringMode: 'new' }), env: { ...decodoEnv(), ...PPE_ENV } });
        assert.equal(run3.code, 0, run3.output);
        assert.equal(readDataset(storageDir).length, 0);
        assert.equal(chargeTotals(storageDir).result ?? 0, 0);
    });
});

describe('pay-per-event limit', () => {
    test('stops the crawl when ACTOR_MAX_TOTAL_CHARGE_USD is exhausted (local price = $1/event)', async () => {
        mock.state.version = 2;
        const storageDir = makeStorageDir('limit');
        const run = await runActor({
            storageDir,
            input: baseInput({ pushBatchSize: 1, skipProxyHealthCheck: true }),
            env: { SOURCE_BASE_URL: mock.url, ...PPE_ENV, ACTOR_MAX_TOTAL_CHARGE_USD: '3' },
        });
        assert.equal(run.code, 0, run.output);
        const items = readDataset(storageDir);
        const charged = chargeTotals(storageDir).result;
        assert.equal(items.length, 3, 'exactly budget / price items saved');
        assert.equal(charged, items.length, 'saved items == charged items (no free or unbilled items)');
        const summary = readKv(storageDir, 'RUN_SUMMARY');
        assert.equal(summary.chargeLimitReached, true);
        assert.equal(summary.saved, 3);
        assert.match(run.output, /Stopping crawl: charge limit reached/);
    });
});

describe('plain local run (no PPE env)', () => {
    test('charging no-ops, maxItems caps output, ids input works, no proxy', async () => {
        mock.state.version = 2;
        const storageDir = makeStorageDir('plain');
        const run = await runActor({
            storageDir,
            input: { ids: ['1', '4', '6', '7'], maxItems: 2, backoffBaseMillis: 20, proxyHealthCheckUrl: `${mock.url}/ip` },
            env: { SOURCE_BASE_URL: mock.url },
        });
        assert.equal(run.code, 0, run.output);
        const items = readDataset(storageDir);
        assert.equal(items.length, 2);
        assert.ok(items.every((i) => i.changeType === 'unmonitored'));
        assert.deepEqual(chargeTotals(storageDir), {}, 'no charging log without ACTOR_TEST_PAY_PER_EVENT');
        // Not a PPE run: Actor.pushData(items, event) pushes everything and charges nothing (apify@3.7.2 charging.js).
        assert.match(run.output, /Charging: payPerEvent=false/);
        assert.equal(readKv(storageDir, 'RUN_SUMMARY').saved, 2);
        assert.match(run.output, /Proxy health check skipped: running without a proxy/);
        assert.equal(readKv(storageDir, 'RUN_SUMMARY').stopReason, 'maxItems (2) reached');
    });

    test('since filter skips old items', async () => {
        mock.state.version = 2;
        const storageDir = makeStorageDir('since');
        const run = await runActor({ storageDir, input: baseInput({ since: '2026-10-01', proxyProvider: 'none' }), env: { SOURCE_BASE_URL: mock.url } });
        assert.equal(run.code, 0, run.output);
        assert.deepEqual(ids(readDataset(storageDir)), ['2', '7']);
    });
});

describe('proxy health check', () => {
    test('fails fast with a clear, redacted error on bad credentials', async () => {
        const storageDir = makeStorageDir('badproxy');
        mock.resetHits();
        const wrong = 'Wr0ng-Pa55word';
        const run = await runActor({ storageDir, input: baseInput(), env: decodoEnv(wrong) });
        assert.notEqual(run.code, 0);
        assert.match(run.output, /Proxy health check failed via Decodo http:\/\/de\*\*\*:\*\*\*@127\.0\.0\.1:\d+/);
        assert.ok(!run.output.includes(wrong), 'wrong password never printed');
        assert.equal(readDataset(storageDir).length, 0);
        assert.equal(mock.state.hits['/api/items'], undefined, 'crawl never started');
    });

    test('decodo provider without credentials is a clear input error', async () => {
        const storageDir = makeStorageDir('nocreds');
        const run = await runActor({ storageDir, input: baseInput({ proxyProvider: 'decodo' }), env: { SOURCE_BASE_URL: mock.url } });
        assert.notEqual(run.code, 0);
        assert.match(run.output, /DECODO_USER \/ DECODO_PASS \/ DECODO_HOST/);
    });
});

describe('unit', () => {
    test('redaction', () => {
        assert.equal(redactProxyUrl('http://user-abc:p%40ss@gate.example:7000'), 'http://us***:***@gate.example:7000');
        assert.equal(scrubSecrets('bad p@ss and p%40ss', ['p@ss']), 'bad *** and ***');
    });
    test('since parsing', () => {
        const now = new Date('2026-10-03T00:00:00Z');
        assert.equal(parseSince('7 days', now).toISOString(), '2026-09-26T00:00:00.000Z');
        assert.equal(parseSince('2026-09-01', now).toISOString(), '2026-09-01T00:00:00.000Z');
        assert.equal(parseSince('', now), null);
        assert.throws(() => parseSince('yesterday-ish', now));
    });
    test('fingerprint ignores volatile fields and key order', () => {
        const a = fingerprint({ id: '1', price: 2, scrapedAt: 'x' }, ['scrapedAt']);
        const b = fingerprint({ price: 2, id: '1', scrapedAt: 'y' }, ['scrapedAt']);
        assert.equal(a, b);
        assert.notEqual(a, fingerprint({ id: '1', price: 3 }, ['scrapedAt']));
    });
});
