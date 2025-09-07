---
title: My day 1 with jj (Jujutsu)
date: 2025-07-09
tag: post
---

> Discuss on [/r/git](https://www.reddit.com/r/git/comments/1lvbzo8/my_day_1_with_jj_jujutsu/) and [Bluesky](https://bsky.app/profile/iutensil.bsky.social/post/3ltnz23tp2k2z)

## TL;DR

I became productive with [jj](https://github.com/jj-vcs/jj) (Jujutsu, *dauntless* version control) on day 1. This is my story, along with my mindset changes, and delicious recipes. Scroll down to the end for a short list of when to use what command/alias.

## Why try `jj`?

Well, *dauntless* is not the official slogan, but I really need it to describe a liberating feeling much stronger than "fearless".

Git is an intimidating black box for some, but I don't fear it in my daily work, as I'm skilled enough to easily recover work if I messed up.

`jj`, on the other hand, gives me the ultimate power in the river of time:

> In `jj`, I can go anywhere in history, do anything, be done with it, and history will reshape itself accordingly.

I wouldn't know this when I first read [Steve's Jujutsu Tutorial](https://steveklabnik.github.io/jujutsu-tutorial/) months ago, it's well written but still a haystack to find the needle that would click with me.

[Jujutsu on tangled](https://blog.tangled.sh/blog/stacking) intrigued me, by telling me "Jujutsu is built around structuring your work into meaningful commits", and showing how it helps contributors to iterate on changes with dependencies on other changes, individually reviewed, reworked, and merged. But what if I just use it on my personal repo, and don't care much about clean history?

[A Newbie's First Contribution to (Rust for) Linux: Git gud](https://blog.buenzli.dev/rust-for-linux-first-contrib/#git-gud) shows the author's Git workflow to contribute to Linux kernel with a lot of fast moving forks. The configuration for `rebase` and `rerere` seems really solving the roadblocks of contributing to a thriving project. But the author said: "Jujutsu is much better at this kind of workflow and what I was actually using most of the time. I first discovered this workflow while using Jujutsu and only later found out you could do something similar with Git." A refreshing remark! Maybe I do need native and friendly support for more advanced features, even just to alleviate my mind.

Eventually, pksunkara's [Git experts should try Jujutsu](https://pksunkara.com/thoughts/git-experts-should-try-jujutsu/), and his side-by-side workflow comparisons with Git, and his [`jj` configuration full of aliases](https://gist.github.com/pksunkara/622bc04242d402c4e43c7328234fd01c) that gave me the first boost, so I finally decided to spend a day with `jj`. I definitely no Git expert, but those aliases really look attempting, what if I can pick my few favorites?

I started the journey with a minimal goal. I just wanted to recover my Git workflow in `jj`, as `jj` coexists with a local Git repo, and I need `jj` to work with my GitHub (or any code forge I might migrate to in future). I learned much more, and they are much easier than I thought.

## Protect my main branch

First thing, I went to my GitHub settings and [protected my main branch](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches), to at least forbid force push, in case (my misuse of) `jj` messes up the remote. ([Here](https://ricky-lim.github.io/blog/protect-your-main-branch-in-github/) is how to do even better from CLI.)

## Install and configure `jj`

I use [just](https://github.com/casey/just) to write code snippets as tasks. Installing `jj` on Mac, and prepare the configurations is simply:

```make
prep-jj:
    which jj || brew install jj
    mkdir -p ~/.config/jj
    cp -f dotfiles/.config/jj/config.toml  ~/.config/jj/config.toml
    jj config set --user user.name "$(git config --get user.name)"
    jj config set --user user.email "$(git config --get user.email)"
    jj config list --no-pager
```

The [`dotfiles/.config/jj/config.toml`](https://github.com/utensil/forest/blob/main/dotfiles/.config/jj/config.toml) is an adapted version from pksunkara's, and all changed places are annotated with `[NOTE]` comments and inspiring links. By copying to the right path, it becomes the user-wide configuration.

`jj config set --user ` will write additional and more personal information into the same file (assuming git has already configured these information), so they came later. Finally, the configuration is listed for inspection.

Every time I've updated the configuration, or I'm on a new machine, I'll run `just prep-jj` again, so I'm all set again. Your way to manage code snippets might be different, but it all boils down to similar few lines.

You might want to change the line `editor = 'hx'` back to favorite editor, as mine is now [Helix](https://github.com/helix-editor/helix).

It also assumed that you have installed [delta](https://github.com/dandavison/delta), a syntax-highlighting pager for git, diff, grep, and blame output. It's eye candy, and makes the diff much more clear.

## Initialize the Git repo

`jj` can coexist, or officially, *colocate* with a local Git repo. I place all my local Git repos under `~/projects/` so my just task looks like this:

```make
init-jj PROJ:
    #!/usr/bin/env zsh
    cd ~/projects/{{PROJ}}
    jj status || jj git init --colocate
```

`jj status` will detect if it's already a `jj` repo, otherwise we will initialize `jj` to colocate with Git. I try to make all my tasks open to reentrance, so I can easily tweak and rerun them.

Actually it's already alias to `jj init` by pksunkara, but here we go with the origin command, to avoid locked-in. But later on, I'll use more aliases, and you may consult [the configuration](https://github.com/utensil/forest/blob/main/dotfiles/.config/jj/config.toml) for the full command.

## Thrown into limbo

Once `jj` is initialized, we are no longer on any branch of Git. If we go back to `git` or `lazygit`, we'll see that we are on a detached state.

I don't know about you, but my feeling was like floating in the air, with no solid ground under my feet.

I felt much better when I learned that what I commit as *change*s in `jj` will still be reflected in Git as commits, and commits can still find their parents.

We can go back and edit a *change* then commit again, it would be become a new Git commit, but its identity as the original *change* remains the same. So changes can still find their parent changes.

Actually, a branch in Git, is just a reference always point to the latest commit of the branch, so its history can be traced via parents.

`jj` has *bookmark* for pointing to a *change*. Unlike in Git, when you commit more changes on top of it, the *bookmark* doesn't move to the latest change automatically, however, *we* can move it.

With these 2 powerful concept, we are lifted off ground, start flying among changes, with bookmarks marking our path.

## The working copy

OK, we are not on any branch, so where are we?

`jj log` (or simple `jj l` or even `jj`) gave me something like these at the top:

```
@  rrptyzpt 0f23c873 (empty) (no description set)
◆  vmzsxwzu f800c4ed My last commit on the main branch
```

That's a lot to take in!

`f800c4ed` and `My last commit on the main branch` can be recognized as my last Git commit hash and message.

`vmzsxwzu` is the *change id* assigned to it, along with a diamond ◆ indicating that it's immutable: It's written on the stars by Git, so we can't edit it.

But what's the commit-like stuff on top of it? I didn't like it, and even tried to `jj abandon` it, but it keeps coming back with a new *change id* and a new commit hash.

Finally, I accepted it as the "working copy", indicated by `@`. Unlike in Git, where I'll be on HEAD, along with some local changes to be staged, in `jj`, I'm already on the future commit as a working copy. That's why sometimes we need `@-` that points to the parent of `@`, the last committed *change*.

`(empty)` means I haven't made any edits to this *change*. `(no description set)` means I haven't described what I'm going to do for this change (via `jj desc`).

I'll feel much better if it's just `(no description)`, as the `set` makes me feel guilty for not providing a description ahead. And it turns out that I didn't need to! Even after I'm done with it, and moved on (`jj` will keep the change in its history, like automatically doing `git stash`). If I have trouble recognizing the change without a description, I could always use `jj d` to inspect the diff.

`jj s` (status) shows it more verbosely:

```
The working copy has no changes.
│Working copy  (@) : rrptyzpt 0f23c873 (empty) (no description set)
│
│Parent commit (@-): vmzsxwzu f800c4ed main | My last commit on the main branch
```

The change id of my working copy begins with `rr` (bold and colored, indicating we can refer to it uniquely with `rr`).

It's a bit annoying to enter and quit pager, and unable to see the latest changes, so I've configured `jj` to use no pager and only occupy about 2/3 screen.

There's also alias `jj lp` that shows private (i.e. not pushed) changes, and `jj lg` that shows all changes, including elided changes that you just pushed.

## Commit

I worked on a repo that I'll also add my just tasks and configurations for `jj` into it. So I edit the justfile in my editor Helix, and saved it to disk.

Alias `jj d` will show the diff, that confirms that `jj` has seen our edits.

We can now commit the change. `jj commit` will commit everything, opening the configured editor for commit message (just save and quit to submit, quit without saving to cancel).

Aliases like `jj ci` will also fire up a built-in diff editor to interactively select which files, or even which parts (called sections) to commit. Arrow keys can fold/unfold files/sections, space to select, `c` to commit, and `q` to quit.

I couldn't find how to commit until I tried `c`, there is no visual hint at all. I tried every possible key combination to trigger the menu, no luck. We can actually use mouse to click on the menus, but I didn't realize that I could do it on day 1.

I often find myself repeatly use `jj ci` to review, select and commit, to split my local edits into a few independent changes.

With alias `jj cim <message>`, we can directly supply the commit message from CLI without opening an editor, then select which parts to commit.

## New

After commit, we'll again on an empty change with no description, so we can continue making new edits.

But if after working for a while, I suddenly want to discard my (uncommitted) edits, I can do `jj n rr` to start over from the last change. The uncommitted edits will be still there in `jj` as a change, but local files will be reset to the state when we commited `rr`.

Here `rr` could be any other change id, or any bookmark, or any *revset* in general. We'll learn more about *revset* later, for now, we just need to know that a change id, a bookmark, `@` and `@-` that we know so far are all *revset* s.

`jj n` (new) effectively spins off a new history line from the parent change. We can go along the line for a few changes, and spin off from anywhere again, without having to create a named branch.

## Edit

In Git, I seldom amend a commit, usually I just use `reword` in lazygit to amend the commit message, or `reset --mixed` (`gm` in lazygit) to discard history after a commit, then stage and commit them in a better way again.

In `jj`, if I don't like a change, I could go back and edit it:

```
jj e <revset>
```

will auto stash any dirty edits, and reset local files to the state of that `<reveset>` (read: change), I can happily do any edits, or commit it with alternative selections of files or sections.

We don't need to explicitly commit, when we use `jj n <revset>` or `jj e <revset>` to jump to anywhere else, the local edits will be automatically committed to the original change.

## Evolution of a change

Wait, what if I messed up when editing a commit, and left it, can I go back?

At that time, it's beyond what `jj undo` can easily do, especially we might be confused by what we did and didn't do.

The first thing we can do is to inspect how a change has evolved over time by

```
jj evolog -r <revset>
```

It looks like this:

```
❯ jj evolog -r uo
○  uoxoknux 92fb8d3a (no description set)-- operation a0693515ab31 (2025-07-09 11:54:16) snapshot working copy
○  uoxoknux hidden 1f73cdfd (no description set)-- operation 79813357f450 (2025-07-09 11:52:58) snapshot working copy
○  uoxoknux hidden c2bf8f4f (empty) (no description set)-- operation a22c21ce9fc1 (2025-07-09 11:52:32) new empty commit
```

We can inspect the diffs of each hidden commits with their commit hash via `jj dr <revset>` (alias for `diff -r`) where `<revset>` should be the commit hash to disambiguate.

The we can use either `jj n` or `jj e` on the commit hash of our choosing, to continue work.

Note that the change id would become ambiguous, so we need to `jj ad` one of the commit hash so we can continue to refer to the change id.

It looks like this for me:

<details>
<summary>click to expand</summary>
<pre>
❯ jj n 1f73
Working copy  (@) now at: unyrkpru 003d7750 (empty) (no description set)
Parent commit (@-)      : uoxoknux?? 1f73cdfd (no description set)
Added 0 files, modified 1 files, removed 0 files

❯ jj e 1f73
Working copy  (@) now at: uoxoknux?? 1f73cdfd (no description set)
Parent commit (@-)      : mxowtxvr 68b37035 (no description set)

❯ jj evolog -r uo
Error: Revset `uo` resolved to more than one revision
Hint: The revset `uo` resolved to these revisions:
  uoxoknux?? 92fb8d3a (no description set)
  uoxoknux?? 1f73cdfd (no description set)

Hint: Some of these commits have the same change id. Abandon the unneeded commits with `jj abandon <commit_id>`.

❯ jj ad 92f
Abandoned 1 commits:
  uoxoknux?? 92fb8d3a (no description set)
Rebased 1 descendant commits onto parents of abandoned commits
</pre>
</details>

We may also use `jj op diff --op <operationid>` to inspect meta changes of an operation (it has `--from` `--to` variant so it also works on a range of operations).

## PR with an ad hoc branch

> see also the official doc [Working with GitHub: Using a generated bookmark name](https://jj-vcs.github.io/jj/latest/github/#using-a-generated-bookmark-name)

If I like my changes so far on the current history line, I could open an unnamed PR by first commiting changes, then using alias

```
jj prw
```

where `prw` stands for PR working copy.

Per our config, it will push to a branch named `jj/<changeid>` on origin, then open a PR via `gh` (Github's official CLI to interact with issues, PRs, etc.). It will ask you for a title (default to the description of the first change), and a body, we could just press enter all the way to submit, and change anything later.

Personally I think such a tiny ad hoc PR is a good way to record the proposed changes, even for a personal repo. But if pushing to a branch is all you need, alias `jj pscw` (push changes of working copy) will do.

After merging the PR, we need

```
jj git fetch
```

to let both Git and `jj` to learn about the changes.

Here is how `jj l` looked like after I PR a change "Make a start on trying jj" as `#1`, merged it on GitHub, then fetched the changes:

```
◆  rzyozkll 929fe190 main Make a start on trying jj (#1)
│ 
◆  vmzsxwzu f800c4ed My last commit on the main branch
```

`gh pr view #1 -w` can open the PR in the browser.

If we have made edits to the change (but not new changes on top of it, because they would be pushed to their own `jj/<changeid>` branch), like `jj e` or `jj sqar` (introduced below), we can use

```
jj pscw
```

where `pscw` stands for pushing local changes of working copy.

The result looks like this:

```
Changes to push to origin:
  Move sideways bookmark jj/stwxmxoqkyym from 33c46b992efc to 4d3c2a60e0d2
remote: Resolving deltas: 100% (3/3), completed with 3 local objects.
```

If we have made other changes on top of the change, we can treat `jj/<changeid>` as a named branch like below (i.e. `jj bs jj/<changeid> -r <latest changeid>` and `jj psb jj/<changeid>`).

## PR with a named branch

This would best resemble a usual GitHub workflow.

First we create a local bookmark:

```
jj bs <bookmark> -r <revset>
```

`<revset>` could be just a change id, `@-` could come in handy to refer to the last committed change.

`<bookmark>` is the name of the bookmark, just like a normal branch name. And `bs` is the alias for `bookmark set`.

We can see if the bookmark is correctly placed from `jj l`. If we don't like it, we can either `jj undo` or `jj bd <bookmark>` (bookmark delete).

Then we can PR that bookmark:

```
jj prb <bookmark>
```

This would push to a branch named `<bookmark>` on GitHub, then use `gh` to PR it.

It looks like working on a branch in Git, but after we commit more changes, we need to call `jj bs -r <revset>` to set it to desired `<revset>`, then

```
jj psb <bookmark>
```

Note that the alias begins with `ps` instead of `pr`, meaning "push bookmark".

## Fetching

What if we committed some changes on GitHub, like accepting a review suggestion, we need to use `jj git fetch` to make `jj` know about the changes. We'll see something like

```
bookmark: our-name-of-bookmark@origin [updated] tracked
```

`origin` is the remote on GitHub. `[updated]` means `jj` noticed the changes on the remote, `tracked` means the local bookmark is also automatically updated.

If it's not tracked, we can use

```
jj bt our-name-of-bookmark@origin
```

to track it.

Here is how `jj l` looks like when I PR a few changes in this way then fetched it:

```
@  nozpulso fd589b2a (empty) (no description set)
○  kpxkrxvm a22ed20a configure-jj* Add frequently used jj command alias
○  tvvoymuu 6808370c Keybindings for builtin diff editor
○  ylnlzpvx b20ac2d1 Adapt jj config from pksunkara
○  rnkttumw f6296b0a Improve configs in `just init-jj`
◆  rzyozkll 929fe190 main Make a start on trying jj (#1)
◆  vmzsxwzu f800c4ed My last commit on the main branch
```

## Rebase

But I didn't get such a clean history from the start. I'd begun with a few fixup commits, and one of the commits is mixed with different changes. And initially, I pushed it with an ad hoc branch, accepted a few review suggestions on Github.

After opening the PR, I've noticed a weird non-empty commit `xm`

```
○  ...more changes...
◆  rzyozkll 929fe190 main Make a start on trying jj (#1)
│ ○  xmnykxym 4dcb41d9 (no description set)
├─┘
◆  vmzsxwzu f800c4ed My last commit on the main branch
```

After inspecting the diff, I believe its changes is absorbed into `rz` (`#1`), so I rebased `xm` on top of `rz` to see if there is any diff left.

```
❯ jj rb -s xm -d rz 
Rebased 1 commits to destination
```

where `rb` stands for `rebase`.

I just need to remember that I'll be rebasing source (`-s`) onto destination (`-d`).

Now I have

```
○  ...more changes...
│ ○  xmnykxym 2f622327 (empty) I think this is what absorbed into #1
├─┘
◆  rzyozkll 929fe190 main Make a start on trying jj (#1)
```

Nice, it's indeed empty, so I can be assured no work is lost.

It's an extremely simple use case, but I'm happy with being able to transplant a parallel change to be on top of another change, without much hassle.

## Squash

There are some other complications:

```
@  ...more changes...
│ ○  zquplvzx 2b572336 configure-jj Update dotfiles/.config/jj/config.toml
│ ○  nmuntxon 746cb300 Fix typo found by copilot
├─┘
○  ...some changes in between...
○  ylnlzpvx b20ac2d1 Adapt jj config from pksunkara
○  rnkttumw f6296b0a Improve configs in `just init-jj`
```

I want to absorb typo fixes `nm` and `zq` into `yl`, how do I do that?

It's as simple as correctly specifying `from` and `to`:

```
❯ jj sqa --from zq --to y
Rebased 3 descendant commits
Working copy  (@) now at: srnwoqzq c831d68c (empty) (no description set)
Parent commit (@-)      : kpxkrxvm 7d911838  jj/vzzzxqvnptov* | Add frequently used jj command alias
Added 0 files, modified 1 files, removed 0 files
```

where `sqa` is short for squash. Note from the output that any changes after them will be properly rebased.

There is also a shortcut if I just want to absorb a change into its parent: `jj sqar <revset>`.

I keep using the word "absorb" but `jj absorb` does a completely different thing. It splits a change, allowing some other changes to absorb it, by "moving each change to the closest mutable ancestor where the corresponding lines were modified last", that sounds like "dissolve" to me.

## Summary

I could go on and try splitting a change, but the above is enough for day 1.

This doesn't demonstrate the full power of `jj`, but imagining how the same things could be done in Git, I'll definitely rather spend the time with `jj`.

I'll wrap up with a summary of the commands/aliases that would be enough for daily work:

### Getting started

| alias | when to use |
|-------|-------------|
| `jj init` | init `jj` in a local Git repo |

### Show

| alias | when to use |
|-------|-------------|
| `l`   | show log, `jj` works better |
| `lp`  | show private log |
| `lg`  | show all log, even elided changes |
| `s`   | show status |
| `w`   | show status and diff |
| `d` | show the diff of current change |
| `dr <revset>` | show the diff of revision `<revset>` |

### Edits

| alias | when to use |
|-------|-------------|
| `n <revset>` | create a new change based on `<revset>` |
| `cm <message>` | commit everything with `<message>` |
| `ci` | commit the change, choose interactively, write commit message in `$EDITOR` | 
| `e <revset>` | edit any `<revset>` after commit |

`<revset>` could be a short change id, a bookmark, and defaults to @ (working copy).

After edit, just go anywhere else (with e or n), the changes will be committed; or an explicit commit will do.

### Working with remote branch

| alias | when to use |
|-------|-------------|
| `git fetch` |  will update local bookmark from remote branch |
| `bt <branch>@origin` | track remote branch |
 
### PR with named branch

| alias | when to use |
|-------|-------------|
| `bs <bookmark> -r <revset>` | move bookmark `<bookmark>` to `<revset>` |
| `psb <bookmark>` | push bookmark to remote branch named `<bookmark>` |
| `prb <bookmark>` |  create a PR from `<bookmark>` to the default branch |

### PR with ad hoc branch

| alias | when to use |
|-------|-------------|
| `prw` | open (committed) working copy as a PR |
| `pscw` | push changes of working copy to remote branch named `jj/<changeid>` |

### History cleanup

| alias | when to use |
|-------|-------------|
| `undo` | undo last jj operation when messed up |
| `rb -s <src> -d <dst>` | rebase `<src>` onto `<dst>` |
| `sqar <revset>` | squash `<revset>` into its parent |
| `sqa --from <src> --to <dst>` | squash `<src>` into `<dst>` |
| `ad <revset>` | abandon a change |
| `evolog <revset>` | show how a change evolve in time |
| `op log` | show log of operations on jj |
| `bd <bookmark>` | delete a bookmark |

These aliases can be found in this [config file](https://github.com/utensil/forest/blob/main/dotfiles/.config/jj/config.toml) which is based on pksunkara's [gist](https://gist.github.com/pksunkara/622bc04242d402c4e43c7328234fd01c).
