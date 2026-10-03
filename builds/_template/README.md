<!--
BUILDER CHECKLIST (delete this comment before publishing)
- H1 = primary keyword people search for ("<Site> Scraper", "<Site> Price Monitor"...). Use it again in the first sentence.
- Replace every TODO. Keep sections in this order; Apify Store renders this file as the Actor page.
- Output example must be a REAL item from a run, trimmed. Pricing numbers must match Console (NOT LIVE until set there).
-->

# TODO Site Scraper

TODO Site Scraper extracts **TODO what (products, listings, profiles...)** from **TODO site** into a clean dataset you can download as JSON, CSV or Excel, or pull through the Apify API. It uses plain HTTP requests (no browser), so runs are fast and cheap, and it can run on a schedule and return **only new or changed items**.

## What does TODO Site Scraper do?

- Scrapes TODO fields: title, price, currency, last-updated date, URL ... (see [Output](#output)).
- Starts from listing/search URLs or a list of item IDs.
- **Monitoring mode**: on scheduled runs, saves only items that are new or changed since the previous run, so you pay only for what changed.
- Retries blocked requests automatically with fresh proxy sessions and backoff.
- Respects your spending limit: the run stops cleanly when the maximum charge you set is reached.

## Use cases

- TODO: Price monitoring / competitor tracking
- TODO: Lead lists / market research
- TODO: Feeding a spreadsheet, database or AI agent with fresh TODO data on a schedule

## How to use TODO Site Scraper

1. Click **Try for free**.
2. Paste one or more start URLs, or enter item IDs.
3. Set **Max items** to cap the run (and the cost).
4. Optional: set **Monitoring mode** to *New and changed items* and create a **Schedule** to receive only changes.
5. Click **Start** and download the results from the **Output** tab.

## Input

| Field | Type | Description |
|---|---|---|
| `startUrls` | array | Listing or search URLs to start from. |
| `ids` | array | Item IDs to fetch directly. |
| `maxItems` | integer | Stop after this many saved items (0 = no limit). Default 100. |
| `monitoringMode` | `all` / `new` / `newOrChanged` | Save everything, or only new / new-and-changed items vs. earlier runs. |
| `monitoringKey` | string | Optional name for the "seen items" memory; runs with the same key share it. |
| `since` | date or "7 days" | Skip items last updated before this date. |
| `proxyConfiguration` | proxy | Proxy settings. Defaults work for most users. |

Example input:

```json
{
    "startUrls": [{ "url": "https://example.com/api/items?page=1" }],
    "maxItems": 100,
    "monitoringMode": "newOrChanged"
}
```

## Output

Each item in the dataset looks like this (TODO: replace with a real, trimmed item):

```json
{
    "id": "12345",
    "url": "https://example.com/item/12345",
    "title": "Example product",
    "price": 19.99,
    "currency": "USD",
    "updatedAt": "2026-10-01T00:00:00.000Z",
    "changeType": "new",
    "scrapedAt": "2026-10-03T12:00:00.000Z"
}
```

`changeType` is `new` or `changed` in monitoring modes and `unmonitored` when monitoring mode is `all`. A run summary (counts, stop reason, failed URLs) is saved to the key-value store record `RUN_SUMMARY`.

## How much does it cost to scrape TODO Site?

This Actor uses **pay-per-event** pricing: you pay for each saved result, not for compute time.

| Event | Price |
|---|---|
| Actor start (per run, per GB of memory) | TODO — NOT LIVE, set in Console |
| Result (one saved item) | TODO — NOT LIVE, set in Console |

Unchanged items skipped in monitoring mode are **not** charged. Set **Maximum cost per run** in the run options to cap spending; the Actor stops when it is reached.

## FAQ

**Can I get only new items every day?**
Yes. Set *Monitoring mode* to *New and changed items* (or *Only new items*) and add a Schedule. Keep the same input (or the same *Monitoring key*) between runs.

**Why did my run stop before Max items?**
Either the site had no more items, or your *Maximum cost per run* was reached. The `RUN_SUMMARY` record shows the stop reason.

**Do I need proxies?**
TODO: say what the default proxy setup is and when users should change it.

**Is it legal to scrape TODO Site?**
This Actor collects only publicly available data. TODO: note personal data / ToS considerations specific to the source. Consult your lawyer if unsure.

**Something broke or a field is missing.**
Open an issue on the Actor's **Issues** tab with the run ID. TODO: response-time promise.
