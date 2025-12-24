# Gotchas & Pitfalls

Things to watch out for in this codebase.

## [2025-12-24 20:19]
FastTrack was originally tracked as a git submodule (160000 commit) without .gitmodules file. Had to remove submodule reference with 'git rm --cached FastTrack' and copy content from main repo as regular files.

_Context: When working in worktree .worktrees/001-fasting-history-log, the FastTrack directory appeared empty because submodule wasn't initialized. Solution: convert to regular directory content._
