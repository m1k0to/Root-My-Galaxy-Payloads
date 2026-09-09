# SM-F9460 / q5q — 内核恢复与偏移分析(已完成)

> 数据源:F9460ZSS9GZG3 固件 `AP_*_meta_OS16.tar.md5` 中 `boot.img`(v4 头),
> 内核 Image 位于 `0x1000`,kernel_size `0x02cb0a00`(46,860,800B)。
> 恢复产物在 `.analysis/q5q-f9460-zzsgzg3/`。

## 内核身份(已验证)

| 项 | 值 |
|---|---|
| kernel Image sha256 | `235C98F124D4ACCDFC5C7C02C26DB221D0275FAAEC536D47A1FB2A263C80619D` |
| ARM64 magic | `0x644d5241` (ARM\x64) @ +0x38 |
| text_offset | `0x0` |
| vmlinux-to-elf 基址 | `0xffffffc008000000` (= KIMAGE_TEXT_BASE) |
| BTF | `[0x21ef2ac, 0x27bf188)`,6,094,556B,`0xEB9F` 单 blob 校验通过 |
| 符号 | 126,219 条(`nm -n`) |

## 结构体布局一致性(与 dm3q-S918B/S9180 全部精确一致)

| 结构 | 成员 | q5q 偏移 | 说明 |
|---|---|---|---|
| task_struct | cred / real_cred | 0x798 / 0x790 | size 0x1200 |
| rt_mutex_waiter | task/lock/wake/prio/deadline/ww_ctx | 0x30/0x38/0x40/0x44/0x48/0x50 | size 0x58 |
| pipe_buffer | ops | 0x10 | size 0x28 |
| page | flags/_refcount | 0x0/0x34 | size 0x40 |
| work_struct | data/entry/func | 0x0/0x8/0x18 | size 0x30 |
| workqueue_struct | dfl_pwq | 0xb0 | |
| worker_pool | worklist/nr_idle | 0x20/0x34 | |

⟹ **结构与文本布局与 dm3q 相同**,故 target.h 可直接以 dm3q 为模板,仅替换下述数据符号。
(⚠️ dm3q-S918B 的 target.h 注释提到 FZG1 有 +0x80,F9460 与 S9180/S918B 为不同构建,须以本表为准。)

## 符号偏移(q5q 实测,已与 dm3q-S9180 对照)

| 宏 | q5q 实测偏移 | dm3q-S9180 | 差 |
|---|---:|---:|---:|
| INIT_TASK_OFF | 0x02c05080 | 0x02c05080 | 0 |
| ROOT_TASK_GROUP_OFF | 0x02cb9ac0 | 0x02cb9ac0 | 0 |
| SYSTEM_UNBOUND_WQ_OFF | 0x02a90800 | 0x02a90800 | 0 |
| CALL_USERMODEHELPER_EXEC_WORK_OFF | 0x001045d0 | 0x001045d0 | 0 |
| KMALLOC_CACHES_OFF | **0x020646f8** | 0x020641f8 | +0x500 |
| ANON_PIPE_BUF_OPS_OFF | **0x01e7f6e0** | 0x01e7f1e0 | +0x500 |
| ASHMEM_FOPS_OFF | **0x0200d738** | 0x0200d238 | +0x500 |
| ASHMEM_IOCTL_OFF | 0x0114c6dc | — | 0 |
| ASHMEM_COMPAT_IOCTL_OFF | 0x0114cd38 | — | 0 |
| ASHMEM_MMAP_OFF | 0x0114cd90 | — | 0 |
| ASHMEM_OPEN_OFF | 0x0114d070 | — | 0 |
| ASHMEM_RELEASE_OFF | 0x0114d108 | — | 0 |
| ASHMEM_SHOW_FDINFO_OFF | 0x0114d224 | — | 0 |
| CONFIGFS_READ_ITER_OFF | 0x005d7420 | — | 0 |
| CONFIGFS_BIN_WRITE_ITER_OFF | 0x005d7e48 | — | 0 |
| NOOP_LLSEEK_OFF | 0x004bbd34 | — | 0 |
| COPY_SPLICE_READ_OFF | (符号为 `generic_file_splice_read` 0x00528198;`copy_splice_read` 未导出) | — | — |

## 待精确恢复(数据对象,不能套增量)

- `SELINUX_ENFORCING_OFF`(selinux 的 enforcing bool)
- `ASHMEM_MISC_FOPS_OFF`(ashmem miscdevice 的 fops 指针)
- `SLIDE_NFULNL_LOGGER_NAME_OFF` / `SLIDE_NFULNL_LOGGER_OBJECT_OFF`(nfnetlink_log 对象与字符串)
- `SLIDE_RANDOM_TABLE_BOOT_ID_DATA_PTR_OFF` / `SLIDE_SYSCTL_BOOTID_OFF`(boot_id 数据指针)

这些对象不为同名导出符号,需按 `docs/PORTING.md` 的方法(字符串引用反查 / ksymtab / BTF 数据段定位)逐一定址。

## 无法离线确定的硬件/构建项

1. **P0 相关**(`P0_KERNEL_PHYS_LOAD`、`P0_PHYS_OFFSET`、`p0_fingerprint.h`、`SLIDE_P0_OFFSET_CANDIDATES`):
   需真机探测物理页指纹(`tools/generate_p0_fingerprint.pl`),离线不可得。
2. **KernelSU 内核模块**:vermagic 须为
   `5.15.189-android13-8-33404244-abF9460ZSS9GZG3 ...`
   需三星 **q5q(F9460) OSS 内核源码** + KernelSU 补丁重新编译,当前缺失。

## 结论

偏移层面主体已完成:文本/结构布局与 dm3q 全同,核心符号偏移已实测。
剩余:数据对象定址(可离线)、P0 真机探测(设备在环)、KernelSU 内核模块(需三星源码)。
