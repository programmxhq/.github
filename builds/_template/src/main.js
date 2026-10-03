// Entry point. Wiring only: source-specific logic lives in routes.js.
import { setTimeout as sleep } from 'node:timers/promises';

import { CheerioCrawler, SessionError } from '@crawlee/cheerio';
import { Actor, log } from 'apify';

import { ResultSink } from './charge.js';
import { normalizeInput } from './input.js';
import { defaultMonitoringKey, MonitorState } from './monitor.js';
import { collectSecrets, createProxy, proxyHealthCheck, scrubSecrets } from './proxy.js';
import { buildStartRequests, createRouter, detectBlock, getRecordDate, SOURCE_NAME, VOLATILE_FIELDS } from './routes.js';

const MAX_BACKOFF_MS = 30_000;

await Actor.init();

let secrets = [];
try {
    const input = normalizeInput(await Actor.getInput());

    // --- Proxy + fail-fast health check -------------------------------------------------
    secrets = collectSecrets(input); // before createProxy, so its errors are scrubbed too
    const proxy = await createProxy(input);
    log.info(`Proxy: ${proxy.label}`);
    if (!input.skipProxyHealthCheck) await proxyHealthCheck(proxy, input.proxyHealthCheckUrl);

    // --- Persisted run state (survives migrations: default KV store is kept) ---------------
    const runState = await Actor.useState('RUN_STATE', {
        stats: { received: 0, skippedOld: 0, skippedUnchanged: 0, skippedDuplicate: 0, saved: 0, dropped: 0 },
        failedRequests: 0,
        failedUrls: [],
    });

    // --- Monitoring state (persists across runs: named KV store) ---------------------------
    const monitor = new MonitorState({
        mode: input.monitoringMode,
        storeName: `${SOURCE_NAME}-monitor`,
        key: input.monitoringKey || defaultMonitoringKey(input),
        volatileFields: VOLATILE_FIELDS,
    });
    await monitor.load();

    let crawler;
    const sink = new ResultSink({
        monitor,
        maxItems: input.maxItems,
        sinceDate: input.sinceDate,
        batchSize: input.pushBatchSize,
        getRecordDate,
        onStop: (reason) => crawler?.stop(reason),
    });
    sink.stats = runState.stats;
    sink.init();

    // --- Graceful migration / abort: save buffered items and monitoring state -----------------
    const persist = async () => {
        await sink.flush();
        await monitor.save();
    };
    Actor.on('persistState', persist);
    Actor.on('migrating', persist);
    Actor.on('aborting', persist); // the SDK calls Actor.exit() itself after `aborting`

    // --- Crawler ----------------------------------------------------------------------------------
    const router = createRouter({ sink });
    crawler = new CheerioCrawler({
        proxyConfiguration: proxy.proxyConfiguration,
        maxConcurrency: input.maxConcurrency,
        maxRequestRetries: input.maxRequestRetries,
        maxSessionRotations: input.maxRequestRetries, // bounds retries caused by detectBlock (SessionError)
        navigationTimeoutSecs: input.requestTimeoutSecs,
        requestHandlerTimeoutSecs: input.requestTimeoutSecs + 30,
        additionalMimeTypes: ['application/json'],
        useSessionPool: true,
        persistCookiesPerSession: true,
        // 401/403/429 retire the session and retry (crawlee default, made explicit here).
        sessionPoolOptions: { blockedStatusCodes: [401, 403, 429] },

        async requestHandler(ctx) {
            if (sink.stopped) return;
            const reason = detectBlock(ctx);
            if (reason) throw new SessionError(`Blocked: ${reason}`); // retires session, retries
            await router(ctx);
        },

        // Called before each retry: exponential backoff with jitter.
        async errorHandler({ request }, error) {
            const base = Math.min(MAX_BACKOFF_MS, input.backoffBaseMillis * 2 ** request.retryCount);
            const waitMs = Math.round(base * (0.5 + Math.random() * 0.5));
            log.warning(
                `Retry ${request.retryCount + 1}/${input.maxRequestRetries} for ${request.url} in ${waitMs} ms: ${scrubSecrets(error.message.split('\n')[0], secrets)}`,
            );
            await sleep(waitMs);
        },

        async failedRequestHandler({ request }, error) {
            runState.failedRequests++;
            if (runState.failedUrls.length < 50) runState.failedUrls.push(request.url);
            log.error(`Gave up on ${request.url}: ${scrubSecrets(error.message.split('\n')[0], secrets)}`);
        },
    });

    await crawler.run(buildStartRequests(input));
    await persist();

    const summary = {
        ...runState.stats,
        failedRequests: runState.failedRequests,
        failedUrls: runState.failedUrls,
        stopReason: sink.stopReason,
        chargeLimitReached: Boolean(sink.stopReason?.startsWith('charge limit')),
        monitoringMode: input.monitoringMode,
        monitoringKey: monitor.key,
        finishedAt: new Date().toISOString(),
    };
    await Actor.setValue('RUN_SUMMARY', summary);
    log.info('Run summary', summary);
    if (sink.flushError) throw new Error(`Saving results failed, run stopped early: ${sink.flushError.message ?? sink.flushError}`);
    await Actor.setStatusMessage(
        `Saved ${summary.saved} items` +
            (summary.skippedUnchanged ? `, ${summary.skippedUnchanged} unchanged skipped` : '') +
            (summary.failedRequests ? `, ${summary.failedRequests} requests failed` : '') +
            (summary.stopReason ? ` (stopped: ${summary.stopReason})` : ''),
        { isStatusMessageTerminal: true },
    );
    await Actor.exit();
} catch (err) {
    const message = scrubSecrets(err?.message ?? String(err), secrets);
    log.error(message);
    await Actor.fail(message);
}
