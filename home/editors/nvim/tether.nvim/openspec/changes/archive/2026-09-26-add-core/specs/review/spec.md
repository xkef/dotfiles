# Spec Delta

## Purpose

Review what an agent changed in one buffer, hunk by hunk, with accept, reject,
and comments, independent of which agent made the change.

## ADDED Requirements

### Requirement: Review buffer

`:Tether review [scope]` SHALL open one buffer that shows the diff of the scope
grouped by file. Scopes SHALL be `turn` (latest turn, the default), `change`
(the working-copy change against its parent), `checkpoint`, and `since` (from
the latest turn's start to now). The first line SHALL name the scope, agent, and
turn summary, and the second SHALL count files, hunks, and unreviewed hunks.

#### Scenario: Latest turn by default

- **WHEN** a turn edited two files and the user runs `:Tether review`
- **THEN** the buffer lists both files with their hunks and reports two files in
  its summary line

#### Scenario: Empty scope

- **WHEN** the scope has no changes
- **THEN** the buffer states that there is nothing to review

### Requirement: Hunk navigation

In the review buffer `]h` and `[h` SHALL move to the next and previous
unreviewed hunk across files, wrapping at the ends.

#### Scenario: Skip reviewed hunks

- **WHEN** the first of three hunks is accepted and the cursor is on the first
  line
- **THEN** `]h` moves to the second hunk

### Requirement: Accept

`a` SHALL mark the hunk under the cursor as reviewed and `A` every hunk of the
file under the cursor. Reviewed state SHALL persist across restarts, keyed by a
hash of the path and the hunk's changed lines. After accepting, the cursor SHALL
move to the next unreviewed hunk.

#### Scenario: Accepted hunk stays accepted

- **WHEN** the user accepts a hunk, closes the review, and opens it again
- **THEN** the hunk shows as reviewed and the unreviewed count dropped by one

### Requirement: Reject

`x` SHALL revert the hunk under the cursor in the working file and `X` every
hunk of the file. When the hunk's new lines no longer match the file, reject
SHALL leave the file unchanged and report the mismatch. A loaded buffer for the
file SHALL receive the change and be written.

#### Scenario: Reject restores old lines

- **WHEN** a hunk replaced `b` with `B` and the user presses `x` on it
- **THEN** the working file contains `b` again and the review refreshes

#### Scenario: Reject after further edits

- **WHEN** the file changed again at the hunk's lines after the review opened
- **THEN** `x` leaves the file unchanged and reports that the hunk is stale

### Requirement: Comments

`c` SHALL prompt for a comment on the diff line under the cursor and show it
below that line. `:Tether comment` SHALL do the same for the cursor line of a
file buffer. Comments SHALL stay pending until sent or cleared.

#### Scenario: Comment anchored to the new line number

- **WHEN** the user comments on an added line that is line 12 of the new file
- **THEN** the pending comment records the path and line 12

### Requirement: Side-by-side diff

`<CR>` on a file or hunk SHALL open the file against the scope's base in a new
tab, with the base in a scratch buffer next to the working file, both in diff
mode. `q` in the scratch buffer SHALL close the tab.

#### Scenario: Built-in diff tab

- **WHEN** the user presses `<CR>` on a file
- **THEN** a new tab shows two windows with 'diff' set, one of them a scratch
  buffer holding the base content

### Requirement: Quickfix export

`gq` in the review buffer and `:Tether hunks` SHALL fill the quickfix list with
one entry per unreviewed hunk at its first new line.

#### Scenario: Hunks to quickfix

- **WHEN** the scope has three unreviewed hunks and the user runs
  `:Tether hunks`
- **THEN** the quickfix list holds three entries with file and line

### Requirement: Help

`g?` SHALL list the review buffer's keys.

#### Scenario: Key help

- **WHEN** the user presses `g?` in the review buffer
- **THEN** the plugin shows the keys and their actions
