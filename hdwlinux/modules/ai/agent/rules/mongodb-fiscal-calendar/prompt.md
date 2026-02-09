# MongoDB Fiscal Year Calendar

MongoDB's fiscal year runs from **February 1 to January 31**. All quarter references must use the fiscal year format.

## Quarter Definitions

| Quarter | Date Range | Example |
|---------|------------|---------|
| **Q1** | Feb 1 - Apr 30 | FY27 Q1 = Feb 1, 2026 - Apr 30, 2026 |
| **Q2** | May 1 - Jul 31 | FY27 Q2 = May 1, 2026 - Jul 31, 2026 |
| **Q3** | Aug 1 - Oct 31 | FY27 Q3 = Aug 1, 2026 - Oct 31, 2026 |
| **Q4** | Nov 1 - Jan 31 | FY27 Q4 = Nov 1, 2026 - Jan 31, 2027 |

## Naming Convention

**Always** refer to quarters with their fiscal year and quarter name:

✅ Correct:
- `FY27 Q1`
- `FY26 Q4`
- `FY28 Q2`

❌ Incorrect:
- `Q1 2026`
- `Q1`
- `2026 Q1`
- `1Q27`

## Fiscal Year Calculation

The fiscal year number is the calendar year in which the fiscal year **ends**.

- FY26 ends January 31, 2026 (started Feb 1, 2025)
- FY27 ends January 31, 2027 (started Feb 1, 2026)
- FY28 ends January 31, 2028 (started Feb 1, 2027)

## Quick Reference

To convert calendar date to fiscal quarter:
- **Feb - Apr**: Q1 of current calendar year's FY (FY = calendar year + 1 if before Feb)
- **May - Jul**: Q2 of current calendar year's FY
- **Aug - Oct**: Q3 of current calendar year's FY
- **Nov - Jan**: Q4 (Nov-Dec = current FY, Jan = previous FY started)

Example: Today is January 19, 2026
- Current fiscal quarter: **FY26 Q4** (Nov 1, 2025 - Jan 31, 2026)
- Next fiscal quarter: **FY27 Q1** (Feb 1, 2026 - Apr 30, 2026)

