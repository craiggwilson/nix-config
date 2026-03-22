# Version Control: Jujutsu (jj)

This project uses Jujutsu (jj) for version control, **not Git**.

Never use `git` commands directly. Always use `jj` commands for all version control operations.

For detailed usage, load the `jujutsu` skill.

## ⚠️ CRITICAL: Pushing Is Restricted to Humans Only

**Agents MUST NOT push changes to any remote under any circumstances.**

- ✅ Committing, squashing, rebasing, and other local operations are permitted
- ❌ `jj git push`, `git push`, or any equivalent remote-publishing command is **strictly forbidden**
- Only the human operator may push changes to a remote

If a task seems to require pushing, stop and ask the human to do it.
