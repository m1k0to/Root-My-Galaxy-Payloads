#!/usr/bin/env bash
# F9460 (q5q) 内核符号 / BTF 恢复流水线
# 前置:tools/extract_kernel.py 已产出 <out>/kernel
# 依赖:vmlinux-to-elf  (pip, ~/.local/bin)、llvm-nm、pahole、bpftool
set -e
K="${1:-kernel}"
OUT="${2:-.analysis/q5q-f9460-zzsgzg3}"
mkdir -p "$OUT"

echo "[1/4] vmlinux-to-elf 恢复符号 ELF"
~/.local/bin/vmlinux-to-elf "$K" "$OUT/vmlinux.elf"

echo "[2/4] 符号表"
llvm-nm --numeric-sort "$OUT/vmlinux.elf" > "$OUT/vmlinux.nm" \
  || $(readelf -sW "$OUT/vmlinux.elf" | awk '{print $1, $2, $8}' | grep -v '^$' > "$OUT/vmlinux.nm")

echo "[3/4] 提取原始 BTF blob"
python3 - "$K" "$OUT/vmlinux.btf" <<'PY'
import sys, struct
image = open(sys.argv[1], "rb").read()
prefix = b"\x9f\xeb\x01\x00"
cands, cur = [], 0
while True:
    start = image.find(prefix, cur)
    if start < 0: break
    cur = start + 1
    if start + 24 > len(image): continue
    magic, ver, flags, hlen, toff, tlen, soff, slen = struct.unpack_from("<HBBIIIII", image, start)
    if magic != 0xEB9F or ver != 1 or flags != 0 or hlen < 24: continue
    plen = max(toff + tlen, soff + slen)
    end = start + hlen + plen
    sstart = start + hlen + soff
    if end > len(image) or sstart >= end or image[sstart] != 0: continue
    cands.append((start, end))
assert len(cands) == 1, f"expected one raw BTF blob, got {cands}"
s, e = cands[0]
print(f"raw BTF: [0x{s:x}, 0x{e:x}) ({e-s} bytes)", file=sys.stderr)
open(sys.argv[2], "wb").write(image[s:e])
PY

echo "[4/4] BTF 转储(raw + c)"
bpftool btf dump file "$OUT/vmlinux.btf" format raw > "$OUT/vmlinux-btf.raw"
bpftool btf dump file "$OUT/vmlinux.btf" format c  > "$OUT/vmlinux-btf.h"

echo "完成 -> $OUT"
