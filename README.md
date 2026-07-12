# WDW Ticket Pricing Analysis

Disney publishes its 1-day ticket prices on a date-based calendar when you go to buy tickets. What it doesn't publish is that calendar as data you can actually analyze. So I built the dataset myself: 477 consecutive days of published prices, July 2026 through October 2027, entered by hand from the ticket calendar.

Then I ran the numbers in SQL (DuckDB) to answer one question: what are you actually paying for when you pick a date?

**What I found:**

- The same base ticket runs $119 to $189 depending on the date. That's a $70 difference for the same park.
- I expected weekends to drive it. They barely do. The weekend premium is $6.73, about 4%. The season is what you pay for: September averages around $131, March around $181.
- Fridays are priced like weekend days. I didn't assume that going in, the data showed it.
- Holidays add about $14.51 over a normal day. Presidents' Day weekend, spring break, and Easter week all sit at the $189 max.
- The cheapest days on the whole calendar are late August and September weekdays, even though kids are out or barely back in school. Florida heat apparently beats the school calendar.

**Files:** `wdw_ticket_prices.csv` is the dataset (no gaps, no duplicate dates). `analysis.sql` is the six queries. To rerun it: install DuckDB, open a terminal in this folder, type `duckdb`, then `.read analysis.sql`.

**Next:** I'm at WDW in August and plan to collect Lightning Lane Multi Pass prices on-site to extend this.
