#!/usr/bin/env python3
"""从三星固件 AP 中提取 boot.img 与内核 Image,并保存可复现 BTF 区间信息。

用法:
  python3 tools/extract_kernel.py AP_xxx.tar.md5 [outdir]

产物:
  <outdir>/boot.img
  <outdir>/kernel            (ARM64 Image)
  <outdir>/kernel_meta.txt   (尺寸/SHA-256/文本偏移)
"""
import sys, os, subprocess, struct, lz4.frame, hashlib

def main():
    ap = sys.argv[1] if len(sys.argv) > 1 else sys.exit(__doc__)
    out = sys.argv[2] if len(sys.argv) > 2 else "."
    os.makedirs(out, exist_ok=True)

    def run(*a):
        subprocess.run(a, check=True, stdout=subprocess.DEVNULL)

    run("tar", "-xf", ap, "boot.img.lz4", "vendor_boot.img.lz4")

    comp = open("boot.img.lz4", "rb").read()
    boot = lz4.frame.decompress(comp)
    open(os.path.join(out, "boot.img"), "wb").write(boot)

    kernel_size = struct.unpack_from("<I", boot, 0x08)[0]
    kernel = boot[0x1000 : 0x1000 + kernel_size]
    open(os.path.join(out, "kernel"), "wb").write(kernel)

    kmeta = (
        f"boot.img size: {len(boot)}\n"
        f"boot.img SHA-256: {hashlib.sha256(boot).hexdigest().upper()}\n"
        f"kernel size: {len(kernel)}\n"
        f"kernel SHA-256: {hashlib.sha256(kernel).hexdigest().upper()}\n"
    )
    open(os.path.join(out, "kernel_meta.txt"), "w").write(kmeta)
    print(kmeta)

if __name__ == "__main__":
    main()
