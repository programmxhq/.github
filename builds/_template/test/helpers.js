// Runs the Actor as a child process against local storage - the same thing `apify run` does,
// without needing apify-cli or network access.
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

export function makeStorageDir(name) {
    const dir = path.join(ROOT, 'storage-test', `${name}-${process.pid}-${Date.now()}`);
    fs.mkdirSync(dir, { recursive: true });
    return dir;
}

export function cleanStorage() {
    fs.rmSync(path.join(ROOT, 'storage-test'), { recursive: true, force: true });
}

export async function runActor({ storageDir, input, env = {}, timeoutMs = 60_000 }) {
    const inputDir = path.join(storageDir, 'key_value_stores', 'default');
    fs.mkdirSync(inputDir, { recursive: true });
    fs.writeFileSync(path.join(inputDir, 'INPUT.json'), JSON.stringify(input));

    // Hermetic env: drop anything that could make the SDK think it is on the platform or use real creds.
    const base = Object.fromEntries(Object.entries(process.env).filter(([k]) => !/^(APIFY_|ACTOR_|CRAWLEE_|DECODO_)/.test(k)));
    const child = spawn(process.execPath, ['src/main.js'], {
        cwd: ROOT,
        env: {
            ...base,
            CRAWLEE_STORAGE_DIR: storageDir,
            APIFY_LOCAL_STORAGE_DIR: storageDir,
            CRAWLEE_LOG_LEVEL: 'INFO',
            ...env,
        },
    });
    let output = '';
    child.stdout.on('data', (d) => (output += d));
    child.stderr.on('data', (d) => (output += d));
    const code = await new Promise((resolve, reject) => {
        const t = setTimeout(() => {
            child.kill('SIGKILL');
            reject(new Error(`Actor timed out. Output:\n${output}`));
        }, timeoutMs);
        child.on('exit', (c) => {
            clearTimeout(t);
            resolve(c);
        });
    });
    return { code, output, storageDir };
}

export function readDataset(storageDir, name = 'default') {
    const dir = path.join(storageDir, 'datasets', name);
    if (!fs.existsSync(dir)) return [];
    return fs
        .readdirSync(dir)
        .filter((f) => /^\d+\.json$/.test(f))
        .sort()
        .map((f) => JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')));
}

export function readKv(storageDir, key, store = 'default') {
    const file = path.join(storageDir, 'key_value_stores', store, `${key}.json`);
    return fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, 'utf8')) : null;
}

/** Sum of chargedCount per event from the SDK's local "charging_log" dataset. */
export function chargeTotals(storageDir) {
    const totals = {};
    for (const row of readDataset(storageDir, 'charging_log')) {
        totals[row.eventName] = (totals[row.eventName] ?? 0) + row.chargedCount;
    }
    return totals;
}
