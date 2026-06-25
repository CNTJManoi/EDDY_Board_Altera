#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Extract a netlist from a Quartus .bdf schematic (geometric + label-based).

Usage: python bdf_netlist.py [Eddy_c.bdf]
Produces: netlist.txt (full) and prints traces for control nets of interest.
"""
import re, sys, collections

PATH = sys.argv[1] if len(sys.argv) > 1 else 'Eddy_c.bdf'
raw = open(PATH, 'rb').read().decode('cp1251', 'replace')

# ---- strip C-style and // comments (outside strings) ----
def strip_comments(s):
    out = []
    i, n = 0, len(s)
    while i < n:
        c = s[i]
        if c == '"':
            j = s.find('"', i + 1)
            if j < 0: j = n
            out.append(s[i:j + 1]); i = j + 1; continue
        if c == '/' and i + 1 < n and s[i + 1] == '*':
            j = s.find('*/', i + 2); i = (j + 2) if j >= 0 else n; continue
        if c == '/' and i + 1 < n and s[i + 1] == '/':
            j = s.find('\n', i); i = j if j >= 0 else n; continue
        out.append(c); i += 1
    return ''.join(out)

txt = strip_comments(raw)

# ---- split into top-level s-expressions ----
def top_blocks(s):
    blocks = []; depth = 0; start = None; instr = False
    for i, c in enumerate(s):
        if c == '"': instr = not instr
        if instr: continue
        if c == '(':
            if depth == 0: start = i
            depth += 1
        elif c == ')':
            depth -= 1
            if depth == 0 and start is not None:
                blocks.append(s[start:i + 1]); start = None
    return blocks

blocks = top_blocks(txt)

PT = re.compile(r'\(pt\s+(-?\d+)\s+(-?\d+)\)')
RECT = re.compile(r'\(rect\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)\)')
TEXT = re.compile(r'\(text\s+"([^"]*)"')

pins = []        # (name, dir, (x,y))
symbols = []     # dict: module, inst, ports=[(name,dir,(x,y))]
segments = []    # ((x1,y1),(x2,y2), label_or_None, is_bus)
junctions = []   # (x,y)

def child_pts(block):
    """top-level (pt ..) directly inside block (depth 1)."""
    res = []; depth = 0; instr = False; i = 0; n = len(block)
    while i < n:
        c = block[i]
        if c == '"': instr = not instr
        if not instr and c == '(':
            if depth == 1 and block[i:i+3] == '(pt':
                m = PT.match(block, i)
                if m: res.append((int(m.group(1)), int(m.group(2))))
            depth += 1
        elif not instr and c == ')':
            depth -= 1
        i += 1
    return res

for blk in blocks:
    head = blk[1:].split(None, 1)[0].rstrip(')')
    if head == 'pin':
        d = 'bidir' if '(bidir)' in blk else ('output' if '(output)' in blk else 'input')
        rm = RECT.search(blk); rx, ry = (int(rm.group(1)), int(rm.group(2))) if rm else (0, 0)
        names = [t for t in TEXT.findall(blk) if t not in ('INPUT', 'OUTPUT', 'BIDIR', 'VCC', 'GND')]
        name = names[0] if names else '?'
        cp = child_pts(blk)
        if cp:
            px, py = cp[-1]
            pins.append((name, d, (rx + px, ry + py)))
    elif head == 'symbol':
        rm = RECT.search(blk); rx, ry = (int(rm.group(1)), int(rm.group(2))) if rm else (0, 0)
        texts = TEXT.findall(blk)
        module = texts[0] if texts else '?'
        inst = texts[1] if len(texts) > 1 else '?'
        ports = []
        for pm in re.finditer(r'\(port\s*\(pt\s+(-?\d+)\s+(-?\d+)\)\s*\((input|output|bidir)\)\s*\(text\s+"([^"]*)"', blk):
            px, py, pdir, pname = int(pm.group(1)), int(pm.group(2)), pm.group(3), pm.group(4)
            ports.append((pname, pdir, (rx + px, ry + py)))
        symbols.append({'module': module, 'inst': inst, 'origin': (rx, ry), 'ports': ports})
    elif head == 'connector':
        cp = child_pts(blk)
        lab = TEXT.search(blk); label = lab.group(1) if lab else None
        is_bus = '(bus)' in blk
        if len(cp) >= 2:
            segments.append((cp[0], cp[1], label, is_bus))
    elif head == 'junction':
        cp = child_pts(blk)
        if cp: junctions.append(cp[0])

# ---- union-find ----
parent = {}
def find(x):
    parent.setdefault(x, x)
    while parent[x] != x:
        parent[x] = parent[parent[x]]; x = parent[x]
    return x
def union(a, b):
    ra, rb = find(a), find(b)
    if ra != rb: parent[ra] = rb

for p in [pt for s in segments for pt in (s[0], s[1])]:
    find(p)

# union segment endpoints
for (a, b, lab, bus) in segments:
    union(a, b)

def on_seg(p, a, b):
    (px, py), (ax, ay), (bx, by) = p, a, b
    if ax == bx == px and min(ay, by) <= py <= max(ay, by): return True
    if ay == by == py and min(ax, bx) <= px <= max(ax, bx): return True
    return False

# junctions: link any segment passing through the junction point
for j in junctions:
    find(j)
    for (a, b, lab, bus) in segments:
        if on_seg(j, a, b): union(j, a)

# attach ports / pins that land on a segment endpoint or mid-segment
def attach(point):
    find(point)
    if point in parent and find(point) is not None:
        pass
    # endpoint match
    matched = False
    for (a, b, lab, bus) in segments:
        if point == a or point == b:
            union(point, a); matched = True
    if not matched:
        for (a, b, lab, bus) in segments:
            if on_seg(point, a, b):
                union(point, a); matched = True; break
    return matched

pin_label_nets = []   # (net_root, pin_name)
for (name, d, p) in pins:
    attach(p)
    pin_label_nets.append((p, name))
for s in symbols:
    for (pname, pdir, p) in s['ports']: attach(p)

# ---- assign labels to components, then merge components sharing a label ----
comp_labels = collections.defaultdict(set)
for (a, b, lab, bus) in segments:
    if lab: comp_labels[find(a)].add(lab)
for (p, name) in pin_label_nets:
    comp_labels[find(p)].add(name)

# merge components that share any label
label_to_root = {}
for root, labs in list(comp_labels.items()):
    for lab in labs:
        if lab in label_to_root: union(root, label_to_root[lab])
        else: label_to_root[lab] = find(root)

# rebuild label->root after merges
def net_name(root):
    labs = set()
    for (a, b, lab, bus) in segments:
        if lab and find(a) == root: labs.add(lab)
    if labs:
        return '/'.join(sorted(labs))
    return 'net@%s' % str(root)

# collect nets: root -> {labels, ports[(inst,module,port,dir)], pins[(name,dir)]}
nets = collections.defaultdict(lambda: {'labels': set(), 'ports': [], 'pins': []})
for (a, b, lab, bus) in segments:
    r = find(a)
    if lab: nets[r]['labels'].add(lab)
for (p, name) in pin_label_nets:
    nets[find(p)]['labels'].add(name)
for (name, d, p) in pins:
    nets[find(p)]['pins'].append((name, d))
for s in symbols:
    for (pname, pdir, p) in s['ports']:
        nets[find(p)]['ports'].append((s['inst'], s['module'], pname, pdir))

# ---- write full netlist ----
with open('tools/netlist.txt', 'w', encoding='utf-8') as f:
    f.write('=== SYMBOL INSTANCES (%d) ===\n' % len(symbols))
    for s in sorted(symbols, key=lambda x: x['inst']):
        f.write('%-8s %-16s @%s\n' % (s['inst'], s['module'], s['origin']))
        for (pname, pdir, p) in s['ports']:
            r = find(p); labs = '/'.join(sorted(nets[r]['labels'])) or '(unnamed)'
            f.write('    %-4s %-14s -> %s\n' % (pdir[:3], pname, labs))
    f.write('\n=== TOP-LEVEL PINS (%d) ===\n' % len(pins))
    for (name, d, p) in sorted(pins):
        r = find(p); labs = '/'.join(sorted(nets[r]['labels'])) or '(unnamed)'
        f.write('%-6s %-14s -> %s\n' % (d, name, labs))
    f.write('\n=== UNNAMED MULTI-TERMINAL NETS ===\n')
    seen_roots = set()
    for r, v in nets.items():
        if v['labels']: continue
        terms = len(v['ports']) + len(v['pins'])
        if terms >= 2:
            f.write('NET (unnamed @%s)\n' % str(r))
            for (name, d) in v['pins']:
                f.write('    PIN  %-6s %s\n' % (d, name))
            for (inst, module, pname, pdir) in sorted(set(v['ports'])):
                f.write('    %-8s %-14s %-4s %s\n' % (inst, module, pdir[:3], pname))
    f.write('\n=== NAMED NETS ===\n')
    named = [(sorted(v['labels']), v) for v in nets.values() if v['labels']]
    for labs, v in sorted(named):
        f.write('NET %s\n' % '/'.join(labs))
        for (name, d) in v['pins']:
            f.write('    PIN  %-6s %s\n' % (d, name))
        for (inst, module, pname, pdir) in sorted(set(v['ports'])):
            f.write('    %-8s %-14s %-4s %s\n' % (inst, module, pdir[:3], pname))

# ---- trace nets of interest ----
INTEREST = ['SCK', 'SCK_I', 'SS', 'MOSI', 'MISO', 'mode[7]', 'mode[0]', 'mode[1]',
            'd_run', 'dac_run', 'dac_stop', 'adc_start', 'start', 'Write_DAC', 'Read_DAC',
            'adr_clr', 'clr_dac', 'adr_en', 'adc_clk0', 'adc_clk1', 'adc_clk2', 'adc_clk3',
            'ad_clk0', 'ad_clk1', 'ad_clk2', 'ad_clk3', 's_load', 's_read',
            'write_d', 'write_di', 'read_d', 'read_dd', 'clk64', 'clk50', 'clko[0]',
            'cmd1', 'cmd2', 'cmd6', 'cmd7', 'cmd9', 'cmd11', 'cmd12', 'cmd14', 'cmd15',
            'aeb', 'out_imp', 'a_en', 'in_sgn']
def trace(label):
    for v in nets.values():
        if label in v['labels']:
            print('NET %s' % '/'.join(sorted(v['labels'])))
            for (name, d) in v['pins']: print('   PIN  %-6s %s' % (d, name))
            for t in sorted(set(v['ports'])): print('   %-8s %-14s %-4s %s' % (t[0], t[1], t[3][:3], t[2]))
            return
    print('NET %s : (not found / unlabeled)' % label)
for lab in INTEREST:
    trace(lab); print()
print('Full netlist written to tools/netlist.txt')
print('symbols=%d pins=%d segments=%d junctions=%d nets(named)=%d' %
      (len(symbols), len(pins), len(segments), len(junctions),
       len([1 for v in nets.values() if v['labels']])))
