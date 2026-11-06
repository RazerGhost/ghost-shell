---
name: bug
description: Write up and diagnose a bug (repro, expected, actual, files, cause) before fixing it.
disable-model-invocation: true
---
Bug: $ARGUMENTS

1. **Repro:** the shortest steps or command; run it if you can.
2. **Expected vs actual:** with the exact error, only the log lines that matter.
3. **Files:** where it fails and what calls it.
4. **Cause:** confirmed or suspected (say which), with the evidence.
5. **Fix:** the proposed change, and the test that would have caught it.

Don't fix it before I've seen this, unless the fix is one line.
