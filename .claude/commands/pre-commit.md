---
description: Pre-commit checks: verify tests, coverage, and suggest commit message
---

Before I make a commit:

1. Determine if there are changes to other files (or parts thereof) that should be committed with the files that have already been staged.
2. Review staged files to make sure code, tests, docs, etc are well-written, with no obvious errors, security issues, or readability issues.
3. Make sure we have appropriate test coverage for the staged code.
4. Check for refactoring/cleanup opportunities in code, tests, docs, etc that have been staged.
5. Verify tests pass (for the code that will be committed).
6. Show me what's staged (or a summary).
7. Suggest a commit message.
