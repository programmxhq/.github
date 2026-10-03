// Monitoring mode: remembers which item IDs (and content fingerprints) earlier runs saved, so a
// scheduled run can save only new / changed items.
//
// State lives in a NAMED key-value store: the default store is per-run, named stores persist
// across runs of the same user (and never expire). The record key separates different inputs.
import { createHash } from 'node:crypto';

import { Actor, log } from 'apify';

const MAX_ENTRIES = 200_000; // keeps the record well under the KV record size limit (~40 bytes/entry)

export function fingerprint(record, volatileFields) {
    const stable = Object.fromEntries(
        Object.keys(record)
            .filter((k) => !volatileFields.includes(k))
            .sort()
            .map((k) => [k, record[k]]),
    );
    return createHash('sha1').update(JSON.stringify(stable)).digest('hex').slice(0, 16);
}

export function defaultMonitoringKey(input) {
    const basis = JSON.stringify({ u: input.startUrls.map((s) => s.url ?? s).sort(), i: [...input.ids].sort() });
    return `seen-${createHash('sha1').update(basis).digest('hex').slice(0, 12)}`;
}

export class MonitorState {
    /**
     * @param {object} o
     * @param {'all'|'new'|'newOrChanged'} o.mode
     * @param {string} o.storeName  named KV store (must be [a-z0-9-])
     * @param {string} o.key        record key inside the store
     * @param {string[]} o.volatileFields fields ignored by the change fingerprint (e.g. scrapedAt)
     */
    constructor({ mode, storeName, key, volatileFields }) {
        Object.assign(this, { mode, storeName, key, volatileFields });
        this.seen = new Map(); // id -> fingerprint (insertion order = age)
        this.dirty = false;
    }

    get enabled() {
        return this.mode !== 'all';
    }

    async load() {
        if (!this.enabled) return;
        this.store = await Actor.openKeyValueStore(this.storeName);
        const saved = (await this.store.getValue(this.key)) ?? {};
        this.seen = new Map(Object.entries(saved.seen ?? {}));
        log.info(`Monitoring (${this.mode}): ${this.seen.size} previously seen items in store "${this.storeName}" / key "${this.key}"`);
    }

    /** Returns 'new' | 'changed' | null (skip). Does not mutate state - call commit() after the item is saved. */
    classify(record) {
        if (!this.enabled) return 'unmonitored';
        const prev = this.seen.get(String(record.id));
        if (prev === undefined) return 'new';
        if (this.mode === 'newOrChanged' && prev !== fingerprint(record, this.volatileFields)) return 'changed';
        return null;
    }

    /** Marks records as seen. Only call for records that were actually saved (and charged). */
    commit(records) {
        if (!this.enabled) return;
        for (const r of records) {
            const id = String(r.id);
            this.seen.delete(id); // re-insert = refresh age
            this.seen.set(id, fingerprint(r, this.volatileFields));
        }
        while (this.seen.size > MAX_ENTRIES) this.seen.delete(this.seen.keys().next().value);
        this.dirty = true;
    }

    async save() {
        if (!this.enabled || !this.dirty) return;
        this.dirty = false;
        await this.store.setValue(this.key, { updatedAt: new Date().toISOString(), seen: Object.fromEntries(this.seen) });
    }
}
