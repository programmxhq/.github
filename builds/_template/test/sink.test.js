// In-process unit tests for ResultSink with a stubbed Actor (no storage, no child process).
// Added by the template review: flush failures and records without an id.
import assert from 'node:assert/strict';
import { beforeEach, test } from 'node:test';

import { Actor } from 'apify';

import { CHARGE_EVENT, ResultSink } from '../src/charge.js';

let pushed;
let charged;
let failNextPush;

// Minimal PPE charging manager: $1 per item, unlimited budget. Mirrors apify@3.7.2
// pushDataAndCharge order: push first, then charge (which can throw, e.g. an API error).
const cm = {
    getPricingInfo: () => ({ isPayPerEvent: true, perEventPrices: { [CHARGE_EVENT]: 1 }, maxTotalChargeUsd: Infinity }),
    getChargedEventCount: () => charged,
    calculateMaxEventChargeCountWithinLimit: () => Infinity,
    getMaxTotalChargeUsd: () => Infinity,
};
Actor.getChargingManager = () => cm;
Actor.pushData = async (batch) => {
    pushed.push(...batch);
    if (failNextPush) {
        failNextPush = false;
        throw new Error('charge API returned 500');
    }
    charged += batch.length;
    return { eventChargeLimitReached: false, chargedCount: batch.length, chargeableWithinLimit: {} };
};

function makeSink() {
    const committed = [];
    const stops = [];
    const monitor = { classify: () => 'new', commit: (rs) => committed.push(...rs) };
    const sink = new ResultSink({ monitor, maxItems: 0, sinceDate: null, batchSize: 2, getRecordDate: () => null, onStop: (r) => stops.push(r) });
    sink.init();
    return { sink, committed, stops };
}

beforeEach(() => {
    pushed = [];
    charged = 0;
    failNextPush = false;
});

test('a failed save (charge throws after push) stops the crawl and drops later items', async () => {
    const { sink, committed, stops } = makeSink();
    await sink.add([{ id: 'a' }, { id: 'b' }]); // batch 1 ok
    failNextPush = true;
    await sink.add([{ id: 'c' }, { id: 'd' }]); // batch 2: pushed, charge throws
    await sink.add([{ id: 'e' }, { id: 'f' }]); // must not be pushed
    await sink.flush();
    assert.ok(sink.flushError, 'error is kept so main.js can fail the run');
    assert.equal(sink.stopped, true);
    assert.match(stops[0], /save failed: charge API returned 500/);
    assert.deepEqual(pushed.map((r) => r.id), ['a', 'b', 'c', 'd'], 'nothing pushed after the failure');
    assert.deepEqual(committed.map((r) => r.id), ['a', 'b'], 'unconfirmed items are not marked seen');
    assert.equal(sink.stats.saved, 2);
});

test('records without an id are rejected loudly instead of collapsing into one "undefined" id', async () => {
    const { sink } = makeSink();
    await assert.rejects(sink.add({ title: 'no id' }), /Record has no "id"/);
    await sink.add([{ id: 0 }, { id: '1' }]); // 0 is a valid id
    await sink.flush();
    assert.deepEqual(pushed.map((r) => r.id), [0, '1']);
});
