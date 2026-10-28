---
name: tidy-sheet
description: Clean a spreadsheet or CSV on a copy in ~/cogent/work (trim spaces, make dates consistent, flag duplicates, reconcile totals) and report every change. Never edits the original and never deletes rows. Use when the user types /tidy-sheet or asks to clean up, fix or tidy a spreadsheet or CSV.
---
# /tidy-sheet

Start by saying: "Tidying a copy of your sheet. Your original will not be touched."

1. Find out which file. If she did not name it, ask. Do not guess.
2. Copy it: `mkdir -p ~/cogent/work && cp "<file>" ~/cogent/work/<name>-tidy.<ext>`. If that name exists, add `-2`. From now on touch only the copy. Never edit the original, even if she asks in passing; say you only work on copies.
3. Look before changing. Count rows and columns, and read the headers and a sample. Tell her what you see in one or two lines.
4. Clean the copy, and write down each change as you make it (cell or row, before, after):
   - Trim extra spaces at the start, end and inside text.
   - Make dates one format, YYYY-MM-DD. If a date is ambiguous (03/04/25), do not guess: leave it and list it.
   - Flag duplicate rows in a new last column named `duplicate?`. Never delete a row.
   - Reconcile totals: recompute each total and subtotal from its rows. Where it does not match, leave the number and list both values.
   - Do not change any other value. Do not fill blanks. Do not touch formulas.
5. Report every change in a list she can check, then the open items (ambiguous dates, duplicates, totals that do not match) and the path of the cleaned copy. If a spreadsheet tool is not available for .xlsx, work on a CSV copy and say so.
6. Say: "Your original is unchanged. Open the copy and look before you use it."
