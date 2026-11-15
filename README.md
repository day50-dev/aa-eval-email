Sends out an email whenever Artificial Analysis posts a new model to their evals page

[`art-analysis.sh`](art-analysis.sh) is the raw shell tool that you're looking for.

Join [the group](https://groups.google.com/g/aa-new-model) then check out other [**DAY50**](https://github.com/day50-dev) stuff.

Also, the script **art-analysis.sh** is a stand-alone.

## How it works (since 2026-11)

Artificial Analysis retired the Coding Index in favor of the **Intelligence
Index** and locked a lot of the data behind their paid API, so the script
combines two free sources:

- **official free Data API** — model list, release dates
  (``GET https://artificialanalysis.ai/api/v2/language/models/free``,
  100 requests / 24 h, responses cached for 2 hours)
- **public leaderboard page** — the CritPt coding score, size class and
  open-weights flag, none of which the free API returns (the old Coding
  Index is gone; exact parameter counts are Pro-API-only). This part is
  best-effort: if the page changes, Score shows `0`, Size shows `-`, but
  the model list, dates and names keep working

- output columns (tab separated): `Score`, `Days`, `Size`, `Name`
  - `Score` = AA CritPt coding benchmark × 100 (`0` when not scored yet)
  - `Days` = days since release (`-1` when the API has no release date)
  - `Size` = tiny / small / medium / large (`-` when unknown)
  - `Name` is prefixed `open  ` when the model has open weights
- `art-analysis.sh` prints scores ascending; `art-analysis.sh anything` prints descending

## Setup

1. Sign in at [artificialanalysis.ai](https://artificialanalysis.ai) and create a
   free API key (API key management).
2. Put it in `.env` next to the script (already gitignored):

```sh
AA_API_KEY=...
```

Attribution to artificialanalysis.ai is required by their free-API terms, so
`mail.sh` signs the email with the source.

Example output (live data, truncated):

```shell
Score Days    Size    Name
----- ------- ------- --------------------------------------
0     101     small   open  Ling 3.0 Tiny
0     103     tiny    open  LFM2.5-2.6B
31.7  73      -       GPT-6 Astra (Max)
35.7  6       -       Claude Fable 5.2 (Xhigh, Default Fallback)
```
