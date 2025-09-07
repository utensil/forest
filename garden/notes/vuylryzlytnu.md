---
title: |
  Digital hygiene: file deletion
date: 2025-08-14
tags:
  - hygiene
---

To avoid unintended file deletion, I'll use the following routine for file deletion.

`rm` is aliased to a warning and do nothing, this is a precaution against muscle memory.

`rip` is used for file and directory deletion, which will only move the file to `/tmp/graveyard-<userid>` by default.

Scripts should only use `rip` to remove files.

Agents are instructed to only use `rip` to remove files.

Of course this doesn't free the disk space.

Actually deletion will use `dua i <directory>` to first inspect the graveyard to identify the directories occupying the most disk space, use `d` to mark deletion, `tab` to the other pane, `ctrl+r` to permanently delete.

I could also inspect other directories, such as `~`, `~/.cache`, etc.

The whole process is very conscious, thus I'm mostly likely intend to delete them.
