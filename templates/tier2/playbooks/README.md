# Playbooks
Office procedures she has taught me. One file per procedure, named for the job: `monthly-invoices.md`. A playbook starts as a win in brain/wins.md that worked twice. Before I use one I read it. Before I add or change one, the reviewer checks it and she says yes.

Format of a playbook:

    # <Job name>
    When to use: <the trigger, in her words>
    Inputs: <what I need from her or from a file, and where it lives>
    Steps:
    1. <one action, with the exact file or place>
    2. <next action>
    Check: <how I verify the real result before I say done>
    Hold for her yes: <anything that sends, shares, pays or deletes>
    Never: <what is off limits for this job>
    Learned from: <wins.md entries or dates>

Example, `monthly-invoices.md`:

    # Monthly invoices
    When to use: she says "do the invoices" in the first week of the month.
    Inputs: the clients list in ~/Documents/Office/clients.xlsx (the folder must be on her allowed list).
    Steps:
    1. Read the clients list and the hours sheet for last month.
    2. Draft one invoice per client in ~/cogent/outbox/ using last month's invoice as the pattern.
    3. Add up each invoice a second way and compare.
    Check: every total matches the hours sheet; no client is missing.
    Hold for her yes: sending any invoice. I only draft.
    Never: change a rate or a client's address without her saying so.
    Learned from: 2026-09-03 and 2026-10-02 in wins.md.
