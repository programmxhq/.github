# Checks labeled-argument order for Effect(...), Cond(...), .make(...) calls; also flags unknown labels.
import sys, glob
from tree_sitter_language_pack import get_parser
ORDERS = {
 'Effect': ['body','mind','heart','bonds','money','income','add','remove','set','clear','text','dies'],
 'Cond': ['min','max','needTraits','noTraits','needFlags','noFlags','minMoney','maxMoney','ambition'],
 'make': ['weight','once','priority','filler','cond'],
 'gamble': ['win','lose'],
}
p = get_parser('swift'); bad = 0
def callee(n, src):
    f = n.children[0]
    t = src[f.start_byte:f.end_byte].decode().strip()
    return t.lstrip('.').split('.')[-1]
def walk(n, src, path):
    global bad
    if n.type == 'call_expression':
        name = callee(n, src)
        if name in ORDERS:
            labels = []
            for c in n.children:
                if c.type == 'call_suffix':
                    for va in c.children:
                        if va.type == 'value_arguments':
                            for a in va.children:
                                if a.type == 'value_argument':
                                    lab = [x for x in a.children if x.type == 'value_argument_label']
                                    if lab: labels.append(src[lab[0].start_byte:lab[0].end_byte].decode())
            order = ORDERS[name]
            idx = []
            for l in labels:
                if l not in order:
                    print(f"{path}:{n.start_point[0]+1}: {name}: unknown label '{l}'"); bad += 1
                else: idx.append(order.index(l))
            if idx != sorted(idx) or len(set(idx)) != len(idx):
                print(f"{path}:{n.start_point[0]+1}: {name}: labels out of order {labels}"); bad += 1
            if name == 'Effect' and 'text' not in labels:
                print(f"{path}:{n.start_point[0]+1}: Effect missing text:"); bad += 1
    for c in n.children: walk(c, src, path)
files = [f for a in sys.argv[1:] for f in (glob.glob(a + '/**/*.swift', recursive=True) if not a.endswith('.swift') else [a])]
for f in files:
    s = open(f, 'rb').read(); walk(p.parse(s).root_node, s, f)
print(f"argcheck: {len(files)} files, {bad} problems"); sys.exit(1 if bad else 0)
