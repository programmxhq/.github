// Saving + pay-per-event charging, in one place.
//
// Every record goes through ResultSink.add(). The sink:
//   1. drops records older than `since` and records monitoring mode says to skip (never charged),
//   2. enforces maxItems,
//   3. buffers and saves in batches with Actor.pushData(batch, CHARGE_EVENT), which pushes and charges
//      atomically and trims the batch to what the user's max-charge budget still allows,
//   4. stops the crawl once the budget or maxItems is exhausted,
//   5. commits monitoring state ONLY for records that were actually saved.
//
// Verified in apify@3.7.2 source (node_modules/apify/dist/charging.js, actor.js):
//   - Not a PPE run (local default, or a non-PPE Actor): Actor.charge()/pushData(items, event) push
//     everything, charge nothing, return chargedCount 0 and log one warning. So local runs no-op.
//   - Local PPE simulation: ACTOR_TEST_PAY_PER_EVENT=true; every event costs $1 locally (hardcoded),
//     including the synthetic apify-default-dataset-item when pushing to the default dataset.
//   - ACTOR_USE_CHARGING_LOG_DATASET=true (local only) logs each charge to the "charging_log" dataset.
//   - pushData's returned chargedCount SUMS all charged events (custom + synthetic), so it is not an
//     item count. We count saved items as the delta of getChargedEventCount(CHARGE_EVENT).
//   - When the budget cannot cover one more item, the SDK still pushes+charges ONE item so the
//     platform notices and kills the run (charging.js calculatePushDataLimits). We stop at the first
//     eventChargeLimitReached AND check the remaining budget before every push, so this never fires
//     (the pre-check matters when the budget is already exhausted before the first item).
//   - pushDataAndCharge pushes FIRST, then charges. If the charge API call throws, the items are in
//     the dataset but may be unbilled. Any flush failure stops the crawl, drops later items and fails
//     the run (main.js), instead of being swallowed and silently continuing.
import { Actor, log } from 'apify';

// BUILDER: event name must match the event configured in Console (see .actor/pay_per_event.json).
// Set to null to rely ONLY on the synthetic `apify-default-dataset-item` event instead.
// Never enable both a custom per-item event and `apify-default-dataset-item` in Console: users pay twice.
export const CHARGE_EVENT = 'result';
const SYNTHETIC_ITEM_EVENT = 'apify-default-dataset-item';

export class ResultSink {
    constructor({ monitor, maxItems, sinceDate, batchSize, getRecordDate, onStop }) {
        Object.assign(this, { monitor, maxItems, sinceDate, batchSize, getRecordDate, onStop });
        this.buffer = [];
        this.chain = Promise.resolve(); // serializes flushes so charge-count deltas are exact
        this.stopped = false;
        this.stats = { received: 0, skippedOld: 0, skippedUnchanged: 0, skippedDuplicate: 0, saved: 0, dropped: 0 };
        this.stopReason = null;
        this.flushError = null;
        this.idsThisRun = new Set();
    }

    init() {
        const cm = Actor.getChargingManager();
        const info = cm.getPricingInfo();
        this.isPpe = info.isPayPerEvent;
        this.cm = cm;
        const prices = info.perEventPrices ?? {};
        if (Actor.isAtHome() && this.isPpe) {
            if (CHARGE_EVENT && !(CHARGE_EVENT in prices)) {
                log.warning(`PPE event "${CHARGE_EVENT}" is not configured for this Actor; it will not be billed.`);
            }
            if (CHARGE_EVENT && prices[CHARGE_EVENT] > 0 && prices[SYNTHETIC_ITEM_EVENT] > 0) {
                log.warning(`Both "${CHARGE_EVENT}" and "${SYNTHETIC_ITEM_EVENT}" are priced: every item is billed twice. Remove one in Console.`);
            }
        }
        log.info(`Charging: payPerEvent=${this.isPpe}, event=${CHARGE_EVENT ?? SYNTHETIC_ITEM_EVENT}, maxTotalChargeUsd=${info.maxTotalChargeUsd}`);
    }

    /** Add one or more records produced by a route handler. */
    async add(records) {
        for (const record of [].concat(records)) {
            this.stats.received++;
            if (this.stopped) {
                this.stats.dropped++;
                continue;
            }
            if (record?.id === undefined || record.id === null || record.id === '') {
                // Without a stable id every record collapses into one ("undefined") and monitoring breaks.
                throw new Error(`Record has no "id" (check the selectors in routes.js): ${JSON.stringify(record).slice(0, 200)}`);
            }
            const id = String(record.id);
            if (this.idsThisRun.has(id)) {
                this.stats.skippedDuplicate++;
                continue;
            }
            const date = this.sinceDate && this.getRecordDate(record);
            if (date && date < this.sinceDate) {
                this.stats.skippedOld++;
                continue;
            }
            const changeType = this.monitor.classify(record);
            if (!changeType) {
                this.stats.skippedUnchanged++;
                continue;
            }
            this.idsThisRun.add(id);
            this.buffer.push({ ...record, changeType, scrapedAt: new Date().toISOString() });
            if (this.maxItems && this.stats.saved + this.buffer.length >= this.maxItems) {
                await this.flush();
                this.stop(`maxItems (${this.maxItems}) reached`);
                return;
            }
            if (this.buffer.length >= this.batchSize) await this.flush();
        }
    }

    /** Save buffered records. Safe to call concurrently and from event handlers. */
    flush() {
        this.chain = this.chain
            .then(() => this.#flushNow())
            .catch((err) => {
                // Pushed-but-not-charged (or lost) items must not go unnoticed: stop and fail the run.
                this.flushError ??= err;
                log.exception(err, 'Saving results failed; stopping the crawl');
                this.stop(`save failed: ${err?.message ?? err}`);
            });
        return this.chain;
    }

    async #flushNow() {
        if (this.buffer.length === 0) return;
        let batch = this.buffer.splice(0);
        if (this.maxItems) {
            const room = Math.max(0, this.maxItems - this.stats.saved);
            this.stats.dropped += Math.max(0, batch.length - room);
            batch = batch.slice(0, room);
        }
        if (this.flushError || this.stopReason?.startsWith('charge limit')) {
            this.stats.dropped += batch.length;
            return;
        }
        if (batch.length === 0) return;

        const countEvent = CHARGE_EVENT ?? SYNTHETIC_ITEM_EVENT;
        // Budget already exhausted: pushing now would make the SDK push + charge one item OVER the
        // user's limit (overcharge-by-one). Stop instead.
        if (this.isPpe && this.cm.calculateMaxEventChargeCountWithinLimit(countEvent) <= 0) {
            this.stats.dropped += batch.length;
            this.stop(`charge limit reached (maxTotalChargeUsd=${this.cm.getMaxTotalChargeUsd()})`);
            return;
        }
        const before = this.cm.getChargedEventCount(countEvent);
        const res = CHARGE_EVENT ? await Actor.pushData(batch, CHARGE_EVENT) : await Actor.pushData(batch);
        const saved = this.isPpe ? this.cm.getChargedEventCount(countEvent) - before : batch.length;

        this.stats.saved += saved;
        this.stats.dropped += batch.length - saved;
        this.monitor.commit(batch.slice(0, saved));

        if (this.isPpe && (res?.eventChargeLimitReached || saved < batch.length)) {
            this.stop(`charge limit reached (maxTotalChargeUsd=${this.cm.getMaxTotalChargeUsd()})`);
        }
    }

    stop(reason) {
        if (this.stopped) return;
        this.stopped = true;
        this.stopReason = reason;
        log.info(`Stopping crawl: ${reason}`);
        this.onStop?.(reason);
    }
}
