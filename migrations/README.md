# Migrations

One-time changes for machines set up by an earlier version of this repo: taking out what an old
setup installed and the current one no longer does. The modules' `setup.sh` describe only how a
machine should be now; how to get there from an older setup is here.

- One script per change, named `<date>-<what>.sh`, run in name order by `ghost migrate` (and at
  the end of every `ghost install` and `ghost update`) from the repo's root, with `modules/lib.sh`
  loaded and sudo's password already asked.
- Each runs once per machine: `~/.local/state/ghost/migrations` lists the ones done. A failing
  one stops the run and stays to run again next time.
- A fresh machine runs them too, so each one checks that what it removes is there and does
  nothing otherwise.
