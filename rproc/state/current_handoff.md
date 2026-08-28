# Current handoff

- checkpoint date: 2026-08-28 Asia/Shanghai
- checkpoint scope: Week 1 preparation and second correctness audit
- safe to compact after this checkpoint is committed and pushed: yes
- last completed study week: none
- next study week: Week 1, 2026-08-31 through 2026-09-06

## Durable decisions

- 5-month mainline: remoteproc first, RPMI gradually; 20h/week.
- STM32MP157 is the mature remoteproc lab; BPI-F3/K1 is the vendor/mainline gap and later RPMI engineering platform.
- No timer or 6-hour watchdog. User starts each week; Codex reads durable state before planning.
- Correctness and reproducible evidence outrank AI reference documents.

## Verified and ready

- Linux v7.2 and RPMI v1.0 source pins are present locally.
- Host tool gate passes after adding the missing `bc` dependency.
- Independent audit build of `drivers/remoteproc/stm32_rproc.o` passed with `CONFIG_STM32_RPROC=y` and Arm GNU 15.2.1.
- Week 1 call chain, RPMI five abstractions, score weights and safety boundary have been audited.

## Pending inputs, not blockers

- Exact STM32 core-board variant, vendor kernel/DTS, M4 firmware and current board runtime.
- BPI-F3 booted mainline commit/config, current U-Boot env, Bianbu runtime and RCPU/RPMI board evidence.
- The P0 request is in `material-requests/initial_lab_preparation.md`; user may provide it in batches.

## Next concrete action

On 2026-08-31, begin `week01/README.md` Monday work. Before any board write, collect inventory and establish a recovery path. The default Week 1 real evidence target is the learner-run STM32 object build, not an unprepared sysfs start/stop.
