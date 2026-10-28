# Always-on box: choose it, harden it, check it

**Stop here unless you already run servers yourself.** If you do not, keep Tier 3 on the laptop. That is a good answer.

An always-on box is a computer that stays on so scheduled jobs and lanes keep running when your laptop is closed. You do not need one to use Tier 3. The nightly tidy and the daily job run fine on your laptop (they run when it wakes). Build the box only after those are stable.

## Choose

| | Spare Mac mini at home | Small cloud VM you own |
|---|---|---|
| Cost | Nothing if you have it. About $5 a month in power. | About $5 to $12 a month. Check the provider's price today. |
| Setup effort | Low. Same Mac tools as your laptop. | Medium. Linux, cron instead of launchd. |
| If it is stolen or the house floods | Disk is local. Encrypt it. | Not applicable. |
| Reachable when home internet is down | No | Yes |
| Who can touch it physically | You | The provider hosts it. You are trusting the provider with the hardware |
| Pick it if | You have the hardware and want the simplest path | You have no spare Mac, or you want it reachable when you travel |

Default advice: use the spare Mac mini if you have one. If not, start a cloud VM only after a month on Tier 3 on your laptop.

## Hardening checklist

Do these in order. Tick each only after you checked it.

- [ ] Disk encryption on. Mac: FileVault (System Settings, Privacy and Security). Cloud VM: encrypted disk option at creation.
- [ ] Automatic security updates on. Mac: System Settings, General, Software Update. Linux: `unattended-upgrades` or the distribution's equivalent.
- [ ] A separate user account just for the agent. Not an administrator. Your personal account is never logged in on this box.
- [ ] Screen lock and a strong password on that account.
- [ ] No personal email, bank, password manager or browser sessions on the box. The box has one job.
- [ ] No public ports. Mac: firewall on, "block all incoming" on. Cloud VM: security group or firewall allows nothing inbound except from the private network.
- [ ] Reached over a private network such as Tailscale. New devices need your approval in the admin page before they join. Turn on key expiry. Remove old devices.
- [ ] Remote login by SSH keys only. Password login off. Check with `ssh -o PreferredAuthentications=password <box>`; it must be refused.
- [ ] The only credential on the box is the agent's own Claude login (a subscription). No cloud keys, no code-hosting tokens, no email access.
- [ ] If the agent needs to push code, give it a deploy key for one repository with write access to nothing else.
- [ ] Private network details (Tailscale as the example; the page names can change, so if you cannot find one, say so and ask the person helping you): sign in to the Tailscale admin console in a browser. On the Machines page, the box and your devices are the only entries. Under Settings, find Device management and turn on device approval. On each Machines entry check key expiry is not disabled. Under Access controls, the box is reachable only from your laptop and phone (no "allow all").
- [ ] SSH listens on the private network only. Linux: in `/etc/ssh/sshd_config` set `ListenAddress` to the box's private-network address, or use Tailscale SSH with access controls. Review `~/.ssh/authorized_keys` on the box now and then every month: it must list only keys you recognise.
- [ ] Linux firewall denies inbound by default: `sudo ufw default deny incoming`, then `sudo ufw enable`.
- [ ] Cloud VM only: no cloud role or instance profile attached to the VM (a leaked agent could use it), the provider account has two-step login, no provider keys on the box, snapshots are encrypted, and a billing alert is set at $20.
- [ ] The box has the SAME guard rails as your laptop: `~/.claude/settings.json` (Tier 1 and 2 version), the hooks, `~/cogent/allowed-folders.txt`, and the gitignore lines. Run `/status` there and the whole Tier 2 verification. Without this the box could run `claude -p` jobs with no guard.
- [ ] Nobody runs `claude` on the box with `--dangerously-skip-permissions` or `--permission-mode bypassPermissions`. The settings disable it; check `/status`.
- [ ] `~/cogent/STOP` test passed on the box (see the guide, panic switch).
- [ ] Canary scan passes and the canary list is not empty.
- [ ] Notifications work and contain no private content.
- [ ] You know how to cut it off from your phone: remove the device in the private network's admin page, and sign out its Claude session at claude.ai.

## Cutting it off

1. `touch ~/cogent/STOP` (over SSH) if you can reach it.
2. Remove the box from the private network. It is now unreachable.
3. Revoke the private network's auth key for the box and delete the node in the admin console.
4. Sign out the box's Claude session: on the box `/logout`, and in claude.ai account settings look for the Claude Code or sessions section (if you cannot find it, change your Claude password).
5. Power it off. Cloud VM: stop it, then delete it when you are done.
6. Rotate any SSH key that was authorised on the box, and check `~/.ssh/authorized_keys` on your other machines was not changed.
7. Change any secret that ever touched it.

## Mac mini: Keychain and scheduled jobs

A scheduled job on a Mac runs only while the account is logged in, and `security find-generic-password` fails when the login keychain is locked. Making that work unattended usually means automatic login, which defeats the screen lock. Do not do that. The simple answer: on the box, run only jobs that need no Keychain (the nightly tidy and the daily summary). Push alerts are then sent when you are logged in, or the job logs "no topic in Keychain" and carries on. If a standard (non-administrator) account runs the jobs, an administrator does the system updates from a separate login.

## Linux note

On a Linux box, use `cron` (`crontab -e`) instead of launchd. Set the folder and headless flag in the line. Example, nightly tidy at 03:15:

```
15 3 * * * COGENT_HOME=$HOME/cogent COGENT_HEADLESS=1 /bin/bash $HOME/cogent/bin/brain-tidy.sh
```

`daily-job.sh` already tries both `date` forms. Replace the Keychain lookup in `notify.sh` with a file outside `~/cogent`, at `~/.config/cogent-ntfy-topic`, permission 600 (`chmod 600`), and add `Read(~/.config/cogent-ntfy-topic)` to the deny rules and the sandbox read-deny list. On Linux the Claude login is a plain file, `~/.claude/.credentials.json`: `chmod 600` it and deny reading it the same way. Tell your agent when you change the notify lookup.
