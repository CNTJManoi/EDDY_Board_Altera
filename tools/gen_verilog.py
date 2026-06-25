#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Generate a structural Verilog copy (Eddy_c.v) of Eddy_c.bdf.

Re-uses the netlist parser in bdf_netlist.py, then emits structural Verilog:
 - top-level pins -> module ports
 - leaf modules (mx_ctrl, hex_ff, mux*, count*, DAC_RAM, ADC_RAM, ...) -> named instances
 - Quartus primitives (DFF, AND2, OR2, NOT, WIRE, GLOBAL, GND, VCC, ALT_OUTBUF_DIFF) -> inline
Bus connectivity is resolved BY NAME (as Quartus does), so bus-rippers map correctly.
"""
import re, sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
os.chdir(ROOT)

# --- run the parser to populate the netlist into namespace G ---
G = {}
sys.argv = ['bdf_netlist.py', 'Eddy_c.bdf']
exec(open(os.path.join(HERE, 'bdf_netlist.py'), encoding='utf-8').read(), G)

symbols = G['symbols']; pins = G['pins']; nets = G['nets']; find = G['find']

# ---------- helpers ----------
def vid(name):
    if re.match(r'^[A-Za-z_][A-Za-z0-9_$]*$', name):
        return name
    return '\\' + name + ' '

def parse_label(lbl):
    m = re.match(r'^(.+?)\[(\d+)\.\.(\d+)\]$', lbl)
    if m: return (m.group(1), int(m.group(2)), int(m.group(3)))
    m = re.match(r'^(.+?)\[(\d+)\]$', lbl)
    if m: return (m.group(1), int(m.group(2)), int(m.group(2)))
    return (lbl, None, None)

def san(base):
    b = base.replace('/', '')
    return b if b else 'n_root'

def label_expr(lbl):
    base, hi, lo = parse_label(lbl)
    vb = vid(san(base))
    if hi is None: return vb
    if hi == lo: return '%s[%d]' % (vb, hi)
    return '%s[%d:%d]' % (vb, hi, lo)

def concat_expr(lbl):
    return '{' + ', '.join(label_expr(p.strip()) for p in lbl.split(',')) + '}'

def pwidth(pname):
    m = re.match(r'^.+?\[(\d+)\.\.(\d+)\]$', pname)
    if m: return abs(int(m.group(1)) - int(m.group(2))) + 1
    return 1

def pbase(pname):
    return re.sub(r'\[.*\]$', '', pname)

PIN_NAMES = set(parse_label(n)[0] for (n, d, p) in pins)
PIN_BASE = {}
for (n, d, p) in pins:
    base, hi, lo = parse_label(n)
    if base not in PIN_BASE: PIN_BASE[base] = [d, None]
    if hi is not None:
        PIN_BASE[base][1] = max(PIN_BASE[base][1] or 0, hi)

# constant roots from GND/VCC
const_root = {}
for s in symbols:
    if s['module'] in ('GND', 'VCC'):
        for (pname, pdir, p) in s['ports']:
            const_root[find(p)] = 0 if s['module'] == 'GND' else 1

def root_terms(r):
    return len(nets[r]['ports']) + len(nets[r]['pins'])

# synthetic names for unnamed multi-terminal nets
synth = {}; synth_w = {}; sc = 0
for r in sorted(nets.keys(), key=lambda x: str(x)):
    if nets[r]['labels'] or r in const_root: continue
    if root_terms(r) >= 2:
        sc += 1; synth[r] = 'w_%d' % sc
        w = 1
        for (inst, module, pname, pdir) in nets[r]['ports']:
            w = max(w, pwidth(pname))
        synth_w[r] = w

def canonical_label(r):
    labs = nets[r]['labels']
    if not labs: return None
    simple = [l for l in labs if ',' not in l]
    concat = [l for l in labs if ',' in l]
    if simple:
        pin_l = [l for l in simple if parse_label(l)[0] in PIN_NAMES]
        if pin_l: return ('simple', sorted(pin_l)[0])
        rng = [l for l in simple if parse_label(l)[1] is not None]
        if rng: return ('simple', sorted(rng)[0])
        return ('simple', sorted(simple)[0])
    if concat: return ('concat', sorted(concat)[0])
    return None

def expr_at(point, want_w):
    r = find(point)
    if r in const_root:
        v = const_root[r]
        return ("{%d{1'b%d}}" % (want_w, v)) if want_w > 1 else ("1'b%d" % v)
    cl = canonical_label(r)
    if cl:
        return concat_expr(cl[1]) if cl[0] == 'concat' else label_expr(cl[1])
    if r in synth: return synth[r]
    return None

# declared internal wires (simple, non-pin labels)
wire_w = {}
for r, v in nets.items():
    for lbl in v['labels']:
        if ',' in lbl: continue
        base, hi, lo = parse_label(lbl)
        if base in PIN_NAMES: continue
        cur = wire_w.get(base, 0)
        if hi is not None: cur = max(cur, hi)
        wire_w[base] = cur

# ---------- emit ----------
GATE = {'AND2':'&','OR2':'|','OR3':'|','OR6':'|','NAND2':'&','NOR2':'|','NOR3':'|'}
INV  = {'NAND2','NOR2','NOR3'}

out = []
ap = out.append
ap('// ============================================================')
ap('// Eddy_c.v -- structural Verilog copy of Eddy_c.bdf (auto-generated)')
ap('// Source: tools/gen_verilog.py from the extracted schematic netlist.')
ap('// Leaf modules reused as-is (AHDL/VHDL/IP); primitives expanded inline.')
ap('// ============================================================')
ap('')

# module port list (dedup by base, keep pin order)
seen = set(); ordered = []
for (n, d, p) in sorted(pins):
    base, hi, lo = parse_label(n)
    if base in seen: continue
    seen.add(base); ordered.append((base, d, PIN_BASE[base][1]))
ap('module Eddy_c (')
plines = []
for base, d, hi in ordered:
    dirkw = {'input':'input','output':'output','bidir':'inout'}[d]
    rng = ('[%d:0] ' % hi) if hi is not None else ''
    plines.append('    %-7s %s%s' % (dirkw, rng, vid(base)))
ap(',\n'.join(plines))
ap(');')
ap('')

# wire declarations
for base in sorted(wire_w):
    hi = wire_w[base]
    rng = ('[%d:0] ' % hi) if hi > 0 else ''
    ap('wire %s%s;' % (rng, vid(san(base))))
for r in sorted(synth, key=lambda x: int(synth[x][2:])):
    w = synth_w[r]; rng = ('[%d:0] ' % (w-1)) if w > 1 else ''
    ap('wire %s%s;' % (rng, synth[r]))
ap('')

# named constants
for r, val in const_root.items():
    cl = canonical_label(r)
    if cl and cl[0] == 'simple':
        ap('assign %s = 1\'b%d;' % (label_expr(cl[1]), val))
ap('')

def inst_key(s):
    m = re.search(r'\d+', s['inst']); return int(m.group(0)) if m else 0

for s in sorted(symbols, key=inst_key):
    mod, inst = s['module'], s['inst']
    P = {pbase(pn): (pn, pt) for (pn, pd, pt) in s['ports']}
    def e(pn):
        if pn in P: return expr_at(P[pn][1], pwidth(P[pn][0]))
        return None
    if mod in ('GND', 'VCC'):
        continue
    if mod in ('WIRE', 'GLOBAL'):
        o, i = e('OUT'), e('IN')
        if o and i: ap('assign %s = %s;   // %s %s' % (o, i, mod, inst))
        continue
    if mod == 'NOT':
        o, i = e('OUT'), e('IN')
        if o and i: ap('assign %s = ~%s;   // NOT %s' % (o, i, inst))
        continue
    if mod in GATE:
        o = e('OUT'); ins = [e(k) for k in ('IN1','IN2','IN3','IN4','IN5','IN6') if k in P]
        expr = (' %s ' % GATE[mod]).join(x for x in ins if x)
        if mod in INV: expr = '~(%s)' % expr
        if o: ap('assign %s = %s;   // %s %s' % (o, expr, mod, inst))
        continue
    if mod == 'DFF':
        c = []
        for sp, vp in (('D','d'),('CLK','clk'),('CLRN','clrn'),('PRN','prn'),('Q','q')):
            if sp in P:
                ex = e(sp)
                if ex is not None: c.append('.%s(%s)' % (vp, ex))
        ap('dff_prim %s ( %s );' % (inst, ', '.join(c)))
        continue
    if mod == 'ALT_OUTBUF_DIFF':
        c = []
        for sp in ('i','o','obar'):
            if sp in P:
                ex = e(sp)
                if ex is not None: c.append('.%s(%s)' % (sp, ex))
        ap('ALT_OUTBUF_DIFF %s ( %s );' % (inst, ', '.join(c)))
        continue
    # real leaf module
    c = []
    for (pname, pdir, pt) in s['ports']:
        ex = expr_at(pt, pwidth(pname)); pid = vid(pbase(pname))
        # --- SPI high-speed fix: preload the MISO 74165 shift registers while the
        # bus is idle (STLD = PA4 = chip-select-deasserted level) instead of the
        # clk64-domain (write_d|read_dd) load pulse, which races the first SCK edge
        # at high speed and makes the master read 0. See Eddy_c.v / ARCHITECTURE.md.
        if mod == '74165_a' and pbase(pname) == 'STLD':
            ex = 'PA4'
        c.append('.%s(%s)' % (pid, ex if ex is not None else ''))
    ap('%s %s (' % (vid(mod), inst))
    ap('    ' + ',\n    '.join(c))
    ap(');')

ap('')
ap('endmodule')

open('Eddy_c.v', 'w', encoding='utf-8').write('\n'.join(out))
print('Wrote Eddy_c.v : %d symbols, %d ports, %d wire-bases, %d synthetic'
      % (len(symbols), len(ordered), len(wire_w), len(synth)))
