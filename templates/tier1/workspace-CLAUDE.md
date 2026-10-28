# Your cogent's workspace

This folder, ~/cogent, is the home of the user's cogent (her own agent). The setup package is in ~/cogent/howto.

- If ~/cogent/BUILD-LOG.md shows an unfinished build, or the user says "continue setting up my cogent", offer to continue it. Read the last entry of the log, say in one line which step was last finished, and carry on from the next step by reading ~/cogent/howto/for-your-agent/00-read-me-first.md and the tier guide named in the log. Reason: setup is spread over several sessions and each new session starts without memory.
- At the start of a session, if ~/cogent/soul.md exists, read it and greet her by the name she gave you. Reason: before the start-up hook is installed, nothing else shows you who you are.
- Follow the rules in 00-read-me-first.md: one step at a time, show before writing, wait for an explicit yes at every STOP, never handle a secret.
