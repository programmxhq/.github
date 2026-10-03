"""Balance simulator for Dealt.

Parses the Swift content files into Python, ports the GameStore rules, and plays
many lives with simple policies. Usage: python3 tools/simulate.py [Dealt] [runs]
"""
import re, sys, glob, random, collections, statistics

SRC = sys.argv[1] if len(sys.argv) > 1 else 'Dealt'
RUNS = int(sys.argv[2]) if len(sys.argv) > 2 else 3000

# ---------- Swift -> Python content translation ----------

def split_strings(s):
    """Yield (is_string, text) chunks; drops // comments outside strings."""
    out, i, buf = [], 0, ''
    while i < len(s):
        c = s[i]
        if c == '"':
            out.append((False, buf)); buf = ''
            j = i + 1
            while s[j] != '"':
                j += 2 if s[j] == '\\' else 1
            out.append((True, s[i:j + 1])); i = j + 1
        elif s.startswith('//', i):
            j = s.find('\n', i); i = len(s) if j == -1 else j
        else:
            buf += c; i += 1
    out.append((False, buf))
    return out

def translate(code):
    parts = []
    for is_str, t in split_strings(code):
        if is_str:
            parts.append(t); continue
        t = t.replace('[:]', '{}')
        t = re.sub(r'(-?\d+)\s*\.\.\.\s*(-?\d+)', r'R(\1,\2)', t)
        t = re.sub(r'\.([A-Za-z_]\w*)\s*\(', r'\1(', t)
        t = re.sub(r'\b([A-Za-z_]\w*)\s*:(?!:)', r'\1=', t)
        t = re.sub(r'\.([A-Za-z_]\w*)', r"'\1'", t)
        t = re.sub(r'\bnil\b', 'None', t).replace('true', 'True').replace('false', 'False')
        parts.append(t)
    s = ''.join(parts)
    s = re.sub(r',\s*\[(\s*(?:sure|gamble)\()', r', choices=[\1', s)
    # dict literals: ['mind'= 60, 'bonds'= -1]  ->  {'mind': 60, 'bonds': -1}
    s = re.sub(r"\[(\s*'\w+'\s*=[^\[\]]*)\]", lambda m: '{' + re.sub(r"('\w+')\s*=", r'\1:', m.group(1)) + '}', s)
    return s

def R(a, b): return (a, b)
def Effect(body=0, mind=0, heart=0, bonds=0, money=0, income=None, add=(), remove=(), set=(), clear=(), text='', dies=False):
    return dict(stats={k: v for k, v in dict(body=body, mind=mind, heart=heart, bonds=bonds).items() if v},
                money=money, income=income, add=list(add), remove=list(remove), set=list(set), clear=list(clear), dies=dies)
def Cond(min={}, max={}, needTraits=(), noTraits=(), needFlags=(), noFlags=(), minMoney=None, maxMoney=None, ambition=None):
    return dict(min=min, max=max, needTraits=list(needTraits), noTraits=list(noTraits), needFlags=list(needFlags),
                noFlags=list(noFlags), minMoney=minMoney, maxMoney=maxMoney, ambition=ambition)
def sure(label, e): return dict(label=label, kind='sure', e=e)
def gamble(label, pct, win=None, lose=None): return dict(label=label, kind='gamble', pct=pct, win=win, lose=lose)
def make(id, ages, emoji, title, body, weight=3, once=True, priority=False, filler=False, cond=None, choices=()):
    return dict(id=id, ages=ages, title=title, weight=weight, once=once, priority=priority, filler=filler,
                cond=cond or Cond(), choices=choices)
NS = dict(R=R, Effect=Effect, Cond=Cond, sure=sure, gamble=gamble, make=make, none=None)
NS['none'] = Cond()

def extract_arrays(s):
    res = {}
    for m in re.finditer(r'static let (\w+): \[Card\] = \[', s):
        i = m.end() - 1; depth = 0; j = i; in_str = False
        while True:
            c = s[j]
            if in_str:
                if c == '\\': j += 1
                elif c == '"': in_str = False
            elif c == '"': in_str = True
            elif c == '[': depth += 1
            elif c == ']':
                depth -= 1
                if depth == 0: break
            j += 1
        res[m.group(1)] = s[i:j + 1]
    return res

cards = []
for f in sorted(glob.glob(f'{SRC}/Content*.swift')):
    for name, arr in extract_arrays(open(f).read()).items():
        py = translate(arr).replace("'none'", 'none')
        try:
            cards += eval(py, NS)
        except Exception as ex:
            print('parse failed', f, name, ex); raise
core = open(f'{SRC}/ContentCore.swift').read()
TRAITS = {}
for m in re.finditer(r"\.(\w+): TraitDef\(.*?perTurn: (\[[^\]]*\]), luck: (-?\d+)", core, re.S):
    pt = {k: int(v) for k, v in re.findall(r'\.(\w+): (-?\d+)', m.group(2))}
    TRAITS[m.group(1)] = (pt, int(m.group(3)))
BIRTH = ['lucky', 'stubborn', 'bookworm', 'daredevil', 'kind', 'cynic']
AMBITIONS = ['fortune', 'renown', 'hearth', 'scholar', 'wanderer', 'elder']

# ---------- Engine port ----------

def stage(age):
    return 'dawn' if age < 12 else 'bloom' if age < 24 else 'build' if age < 48 else 'harvest' if age < 68 else 'dusk'
YEARS = dict(dawn=4, bloom=3, build=4, harvest=4, dusk=3)
COL = dict(dawn=0, bloom=1, build=8, harvest=8, dusk=6)
STAGE_AGES = dict(dawn=(0, 11), bloom=(12, 23), build=(24, 47), harvest=(48, 67), dusk=(68, 104))
cl = lambda v: max(0, min(100, v))

def passes(c, L):
    for k, v in c['min'].items():
        if L['stats'][k] < v: return False
    for k, v in c['max'].items():
        if L['stats'][k] > v: return False
    if any(t not in L['traits'] for t in c['needTraits']): return False
    if any(t in L['traits'] for t in c['noTraits']): return False
    if any(f not in L['flags'] for f in c['needFlags']): return False
    if any(f in L['flags'] for f in c['noFlags']): return False
    if c['minMoney'] is not None and L['money'] < c['minMoney']: return False
    if c['maxMoney'] is not None and L['money'] > c['maxMoney']: return False
    if c['ambition'] and L['ambition'] != c['ambition']: return False
    return True

def eligible(card, L):
    lo, hi = card['ages']
    if not lo <= L['age'] <= hi: return False
    if card['once'] and card['id'] in L['played']: return False
    if L['cool'].get(card['id'], -1) > L['turn']: return False
    return passes(card['cond'], L)

def achieved(L):
    a, s, f = L['ambition'], L['stats'], L['flags']
    if a == 'fortune': return L['money'] >= 1000
    if a == 'renown': return 'famous' in L['traits'] and s['bonds'] >= 60
    if a == 'hearth': return 'married' in f and 'kids' in f and s['bonds'] >= 70
    if a == 'scholar': return s['mind'] >= 85 and 'published' in f
    if a == 'wanderer': return sum(x.startswith('saw_') for x in f) >= 5
    if a == 'elder': return L['age'] >= 90 and s['heart'] >= 50

def apply(e, L):
    for k, v in e['stats'].items(): L['stats'][k] = cl(L['stats'][k] + v)
    L['money'] = max(-999, L['money'] + e['money'])
    if e['income'] is not None: L['income'] = max(0, e['income'])
    for t in e['add']:
        if t not in L['traits']:
            L['traits'].append(t)
            if t == 'workaholic': L['income'] += 5
    for t in e['remove']:
        if t in L['traits']: L['traits'].remove(t)
    L['flags'] |= set(e['set']); L['flags'] -= set(e['clear'])

def luck(L): return sum(TRAITS.get(t, ({}, 0))[1] for t in L['traits'])

def deal(L, rnd, stats):
    el = [c for c in cards if not c['filler'] and eligible(c, L)]
    hand = [c for c in el if c['priority']]; rnd.shuffle(hand); hand = hand[:3]
    pool = [c for c in el if c not in hand]
    while len(hand) < 3 and pool:
        c = rnd.choices(pool, weights=[max(1, c['weight']) for c in pool])[0]
        pool.remove(c); hand.append(c)
    if len(hand) < 3:
        stats['padded'] += 1
        lo, hi = STAGE_AGES[stage(L['age'])]
        fill = [c for c in cards if c['filler'] and c['ages'][0] <= hi and c['ages'][1] >= lo]
        rnd.shuffle(fill); hand += fill[:3 - len(hand)]
    return hand

def score_choice(ch, L, policy, rnd):
    if policy == 'random': return rnd.random()
    def val(e):
        v = sum(e['stats'].values()) + e['money'] * 0.5 - (500 if e['dies'] else 0)
        a = L['ambition']
        goal = {'fortune': ['money'], 'renown': ['famous'], 'hearth': ['married', 'kids'],
                'scholar': ['published'], 'wanderer': ['saw_'], 'elder': []}[a]
        for g in goal:
            if any(x.startswith(g) for x in e['set']) or g in e['add']: v += 40
        if a == 'fortune' and e['income'] is not None: v += (e['income'] - L['income']) * 3
        if a == 'fortune': v += e['money'] * 1.5
        return v
    if ch['kind'] == 'sure': return val(ch['e'])
    p = max(5, min(95, ch['pct'] + luck(L))) / 100
    return p * val(ch['win']) + (1 - p) * val(ch['lose'])

def play(policy, rnd, stats):
    s = lambda b: cl(b + rnd.randint(-10, 10))
    L = dict(age=0, stats=dict(body=s(60), mind=s(50), heart=s(60), bonds=s(60)), money=0, income=0,
             traits=[rnd.choice(BIRTH)], flags=set(), ambition=rnd.choice(AMBITIONS), turn=0,
             played=set(), cool={})
    while True:
        hand = deal(L, rnd, stats)
        for c in hand: stats['seen'][c['id']] += 1
        best = max(((score_choice(ch, L, policy, rnd), ci, ch) for ci, c in enumerate(hand) for ch in c['choices']),
                   key=lambda x: x[0])
        _, ci, ch = best
        card = hand[ci]; stats['played'][card['id']] += 1
        L['played'].add(card['id'])
        for o in hand:
            if o is not card and not o['filler']: L['cool'][o['id']] = L['turn'] + 2
        if ch['kind'] == 'sure': e = ch['e']
        else: e = ch['win'] if rnd.random() * 100 < max(5, min(95, ch['pct'] + luck(L))) else ch['lose']
        apply(e, L)
        if e['dies']: return L, 'card'
        if L['stats']['body'] <= 0: return L, 'body'
        # advance time
        age, st = L['age'], stage(L['age'])
        bd = -5 if age >= 68 else -2 if age >= 40 else 0
        if 'athlete' in L['traits']: bd = int(bd / 2)
        L['stats']['body'] = cl(L['stats']['body'] + bd)
        if age >= 72: L['stats']['mind'] = cl(L['stats']['mind'] - 3)
        if L['stats']['bonds'] < 30: L['stats']['heart'] = cl(L['stats']['heart'] - 2)
        if age >= 24 and 'charmer' not in L['traits']: L['stats']['bonds'] = cl(L['stats']['bonds'] - 2)
        for t in L['traits']:
            for k, v in TRAITS.get(t, ({}, 0))[0].items(): L['stats'][k] = cl(L['stats'][k] + v)
        L['money'] = max(-999, L['money'] + (L['income'] - COL[st] + (3 if 'frugal' in L['traits'] else 0)) * YEARS[st])
        L['age'] = min(104, age + YEARS[st]); L['turn'] += 1
        if L['stats']['body'] <= 0: return L, 'body'
        if L['age'] >= 104: return L, 'cap'
        if L['age'] >= 68:
            risk = max(0, min(95, (L['age'] - 72) * 2 + max(0, 40 - L['stats']['body']) // 2))
            if rnd.random() * 100 < risk: return L, 'oldAge'

def report(policy):
    rnd = random.Random(7)
    stats = dict(padded=0, seen=collections.Counter(), played=collections.Counter())
    ages, money, causes, ach = [], [], collections.Counter(), collections.defaultdict(list)
    for _ in range(RUNS):
        L, cause = play(policy, rnd, stats)
        ages.append(L['age']); money.append(L['money']); causes[cause] += 1
        ach[L['ambition']].append(bool(achieved(L)))
    q = statistics.quantiles(ages, n=10)
    print(f'\n== policy: {policy} ({RUNS} lives)')
    print(f'death age: mean {statistics.mean(ages):.1f}, median {statistics.median(ages)}, p10 {q[0]:.0f}, p90 {q[-1]:.0f}')
    print(f'final money ($k): median {statistics.median(money)}, p90 {statistics.quantiles(money, n=10)[-1]:.0f}, negative {sum(m < 0 for m in money) / RUNS:.0%}')
    print('causes:', dict(causes))
    print('ambition success:', {a: f'{sum(v) / len(v):.0%}' for a, v in sorted(ach.items())})
    print(f'hands padded with fillers: {stats["padded"]}')
    return stats

print(f'parsed {len(cards)} cards, {len(TRAITS)} traits')
report('random')
st = report('greedy')
never = [c['id'] for c in cards if not c['filler'] and st['seen'][c['id']] == 0]
print('never dealt (greedy):', never)
