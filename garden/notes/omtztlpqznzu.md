---
title: |
  Digital Hygiene: file transfer 
date: 2025-08-14
tags:
  - hygiene
---

I fear data lost during file transfer.

Usually I dealing with large number (>>50k) of files, they might be small, or have various peculiarity.

When moving data between devices, it's prudent to use file transfer (copying), not move operation. But if file transfer didn't ensure data integrity, trusting the new copy will lead to deletion of the old copy, potentially causing data lost.

That happened to me multiple times. File transfer could be interrupted, or some files just fail to get through due to permission issues or disk corruption, or the tool itself is buggy and hangs, both Windows explorer and Mac Finder could hang.

The go-to GUI tool for this is [FreeFileSync: Open Source File Synchronization & Backup Software](https://freefilesync.org/). I can be very much assured by its file transfer robustness, pre-comparison (with disk usage stats), excellent progress reporting, and post-comparison.

But if I'm dealing with data on NAS, it would be cumbersome to use a GUI tool.

I need a CLI or TUI for at least progress reporting, and post-comparison.

Recently I finally have a satisfying solution.

`uvx rsyncy` is a wrapper around `rsync` with progress reporting. `rsync` has error-prone options but that can be avoided with pre-verified scripts. It's also not fast enough, and doesn't seem to support resuming transfer for large files, but these are bearable, because I'm definitely doing other stuff during transfer.

I tried `rusync`, which is indeed much faster. But it doesn't preserve a type of crucial metadata: timestamps. This is unfortunately a deal breaker for me, and caused a mess for some of my data before I realized this issue. Might fork it to fix this.

For post-comparison, I have written a Python script around [PsychedelicShayna/jw](https://github.com/PsychedelicShayna/jw).

`jw` is based on the rust library `jwalk` ( which is also behind `dua` that I use in [[vuylryzlytnu | file deletion]]) for traversing deep directories efficiently, and `xxHash` (an extremely fast non-cryptographic hash algorithm) for checking file integrity.

Additionally I've also checked the timestamp mismatch by sampling some files, which is still done in Python. In future I wish to use native implementation and check a larger portion of files.

With `rsyncy` reporting progress for the underlying reliable `rsync`, and `jw` for file integrity and timestamps consistency, I can have great confidence that no data is lost during transfer.

The `jw` hash file could also be used to check file integrity if I have messed around with the new copy. It could also be part of the solution for tracking file movements, and ensuring that I haven't lost anything when I move files around for re-organization.
