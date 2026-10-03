import sys, glob
from tree_sitter_language_pack import get_parser
p = get_parser('swift')
bad = 0
def walk(n, path, src):
    global bad
    if n.type == 'ERROR' or n.is_missing:
        line = n.start_point[0]
        print(f"{path}:{line+1}:{n.start_point[1]+1}: {'MISSING '+n.type if n.is_missing else 'syntax error'} :: {src.splitlines()[line].strip()[:120] if line < len(src.splitlines()) else ''}")
        bad += 1
        return
    for c in n.children: walk(c, path, src)
files = [f for a in sys.argv[1:] for f in (glob.glob(a + '/**/*.swift', recursive=True) if not a.endswith('.swift') else [a])]
for f in files:
    s = open(f).read()
    t = p.parse(s.encode())
    walk(t.root_node, f, s)
print(f"checked {len(files)} files, {bad} problems")
sys.exit(1 if bad else 0)
