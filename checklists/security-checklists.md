# Security checklists

One list per tier, then a short monthly review. These are the items you can check yourself, by looking or by asking your agent to show you. Tick a line only after you have seen the answer. Your agent has its own longer checks and runs them for you. If something does not tick, stop and ask your agent to explain it and fix it with you.

## Tier 1: a coding agent that knows you

- [ ] My cogent runs under my usual Claude login, and I have no API key set that I did not choose.
- [ ] Two-step sign-in is on for my Claude account.
- [ ] I walled off my private folders and a test read of a file in one was refused.
- [ ] I asked the agent to read a dummy `.env` file and it was refused.
- [ ] `soul.md` says who I am and who it works for, and the agent asks before it changes it.
- [ ] My brain is in git, and I have never put a password, key or ID number in it or in a chat.
- [ ] Web lookups ask me each time, and I read the address before I say yes.
- [ ] I know `/rewind` undoes file edits, `/wrap-up` ends a session well, and (from Tier 2) `touch ~/cogent/STOP` stops my cogent.

## Tier 2: guard rails that enforce themselves

- [ ] All Tier 1 items still tick.
- [ ] The agent tried to read a dummy `.env` file and the guard refused it. I saw the refusal.
- [ ] A test write to `soul.md` made the guard ask me first, and I said no.
- [ ] Text from outside that sounds like an order is stored in `quarantine.md` as "the email said...", never as a rule. I tested it once.
- [ ] Today's activity log exists in `~/cogent/audit/` and I read yesterday's.
- [ ] My secrets are in the Mac Keychain, and I typed each one myself in my own Terminal.
- [ ] The second-opinion reviewer checks anything that will be sent or shared, and anything that changes a rule or playbook, before I say yes.
- [ ] I tried the STOP file once, and no add-on (MCP server) is installed unless I can say why.

## Tier 3: a full cogent

- [ ] All Tier 2 items still tick.
- [ ] I ran the STOP drill this month from my own Terminal: created `~/cogent/STOP`, saw actions stop, removed it, saw them resume.
- [ ] The scout only proposes. After a run, `soul.md`, `rules.md` and `claims.md` had no changes I did not make myself.
- [ ] Outbound work (sends, posts, pushes) is a draft in `outbox/` that the reviewer checked and I approved at my computer. Phone alerts only say something is waiting.
- [ ] Every lane shares one brain, there are at most 3 lanes, and each lane's lessons in the journal carry `[lane:<name>]`.
- [ ] `git -C ~/cogent log` shows the brain committed, and `git -C ~/cogent grep -i -E "password|sk-|token" -- brain soul.md` finds no secret.
- [ ] My agent showed me the canary scan (the fake-secret leak check) passing, and the canary list is not empty.
- [ ] I can name my spend caps, and the always-on machine (if any) holds only the agent's own login and can be powered off and signed out.

## Monthly review (15 minutes)

- [ ] Claude Code is up to date (`claude update`), and so is the always-on machine if I have one.
- [ ] I read `/permissions` and removed any allow rule I no longer need.
- [ ] I looked at the last 30 days of the log for blocked actions and odd hours.
- [ ] I checked my account for sessions and devices I do not recognise, and removed them.
- [ ] I looked at `~/cogent/outbox/` and cleared or acted on everything old.
- [ ] I removed any add-on I no longer use.
- [ ] I backed up `~/cogent/` to a private place I control.
- [ ] I asked: is there anything here I no longer need? I turned it off.
