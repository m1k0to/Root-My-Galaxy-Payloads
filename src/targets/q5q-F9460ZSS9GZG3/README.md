# src/targets/q5q-F9460ZSS9GZG3 — 待填充

这是为 SM-F9460(Galaxy Z Fold 5, 内核 `5.15.189-android13-8-33404244-abF9460ZSS9GZG3`)
新建的移植 profile 占位目录。**尚无数据**。

固件到位后,用 `tools/recover_offsets.sh` 恢复内核符号/BTF,再参照
`src/targets/dm3q-S918BXXSAFZF5/target.h`(同为 5.15.189)格式填齐:

- `target.h` — 全部符号/结构偏移宏
- `p0_fingerprint.h` — P0 物理页指纹(generate_p0_fingerprint.pl)

需重点核对的目标符号(Q5Q 特有值,勿直接复制 dm3q):
`INIT_TASK_OFF / ROOT_TASK_GROUP_OFF / SELINUX_ENFORCING_OFF / KMALLOC_CACHES_OFF /
ANON_PIPE_BUF_OPS_OFF / ASHMEM_*_OFF / CONFIGFS_*_OFF / SLIDE_NFULNL_*_OFF /
SLIDE_TRACEFS_*_OFF / CALL_USERMODEHELPER_EXEC_WORK_OFF / P0_KERNEL_PHYS_LOAD`

> 参考:同构建族 `33404244` 的 F731U 已实现(rmg-f731u),与 q5q 偏移差 +0x40。
> 具体数值必须以 F9460ZSS9GZG3 自身内核为准,勿用 dm3q(FZF5,构建 `33413713`)直接套用。
