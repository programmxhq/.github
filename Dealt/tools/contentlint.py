# Content sanity checks for Dealt (no Swift compiler needed).
# - unique card ids, ages cover a dealt age, eligible-card counts per dealt age
# - flags required somewhere are set somewhere; trait cases exist
import re, sys, glob, collections
SRC = sys.argv[1] if len(sys.argv) > 1 else 'Dealt'
files = sorted(glob.glob(f'{SRC}/Content*.swift'))
text = {f: open(f).read() for f in files}
models = open(f'{SRC}/Models.swift').read()
traits = set(re.findall(r'\b(\w+)\b', re.search(r'case lucky[^\n]*\n[^\n]*', models).group(0))) - {'case'}
DEALT = {'dawn': [0,4,8], 'bloom': [12,15,18,21], 'build': list(range(24,45,4)),
         'harvest': list(range(48,65,4)), 'dusk': list(range(68,105,3))}
ALL_AGES = sorted(a for v in DEALT.values() for a in v)
cards = []  # (id, lo, hi, filler, body-text)
for f, s in text.items():
    for m in re.finditer(r'\.make\(\s*"([^"]+)"\s*,\s*(\d+)\s*\.\.\.\s*(\d+)', s):
        start = m.start()
        nxt = s.find('.make(', m.end())
        chunk = s[start: nxt if nxt != -1 else len(s)]
        cards.append((m.group(1), int(m.group(2)), int(m.group(3)), 'filler: true' in chunk, chunk, f))
problems = 0
ids = collections.Counter(c[0] for c in cards)
for i, n in ids.items():
    if n > 1: print(f'duplicate id {i}'); problems += 1
for cid, lo, hi, fl, ch, f in cards:
    if not any(lo <= a <= hi for a in ALL_AGES): print(f'{cid}: ages {lo}...{hi} never dealt'); problems += 1
    for t in re.findall(r'\.(\w+)', ' '.join(re.findall(r'(?:add|remove|needTraits|noTraits):\s*\[([^\]]*)\]', ch))):
        if t not in traits: print(f'{cid}: unknown trait .{t}'); problems += 1
    if len(re.findall(r'\.(?:sure|gamble)\(', ch)) < 2 and not cid.startswith('fill_'):
        print(f'{cid}: fewer than 2 choices'); problems += 1
setf, needf = collections.Counter(), collections.Counter()
for cid, lo, hi, fl, ch, f in cards:
    for grp in re.findall(r'\bset:\s*\[([^\]]*)\]', ch): setf.update(re.findall(r'"([^"]+)"', grp))
    for grp in re.findall(r'needFlags:\s*\[([^\]]*)\]', ch): needf.update(re.findall(r'"([^"]+)"', grp))
for fl in needf:
    if fl not in setf and not fl.startswith('heir_'): print(f'flag "{fl}" required but never set'); problems += 1
print('cards:', len(cards), '| per file:', dict(collections.Counter(c[5].split('/')[-1] for c in cards)))
print('non-filler cards whose age range covers each dealt age:')
row = []
for a in ALL_AGES:
    n = sum(1 for c in cards if not c[3] and c[1] <= a <= c[2]); row.append(f'{a}:{n}')
print('  ' + ' '.join(row))
print('flags set:', dict(setf))
print(f'contentlint: {problems} problems'); sys.exit(1 if problems else 0)
