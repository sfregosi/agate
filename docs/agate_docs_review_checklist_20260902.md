# agate docs site — review checklist

Reviewed from raw `.qmd` source (cloned from `main`) plus the rendered
site nav (`_quarto.yml`). Organized by: **structure/navigation** first
(the big picture), then **page-by-page** fixes.

---

## 1. Structure & navigation — the big-picture stuff

- [ ] **`convert-acoustics.qmd` is orphaned.** It's commented out of the
      sidebar nav in `_quarto.yml`, but it's a real, fairly complete page
      with three sections: *Convert WISPR raw files*, *Convert PMAR raw
      files*, and *WAV↔FLAC conversion*. Two problems:
      - Its **WISPR section duplicates/is superseded by `convert-wispr.qmd`**
        (which is in the nav and is the more current, more detailed
        version — it even has the two-approach structure this page lacks).
      - Its **PMAR section and WAV↔FLAC section are unique** — that
        content doesn't exist anywhere else on the site, but a user can
        only find it by guessing the URL or following an internal link
        from `mission-processing.qmd`. There's currently no way to
        convert PMAR files that a user could discover through the nav.
      - **Suggested fix:** delete the WISPR section from
        `convert-acoustics.qmd` (redundant), rename the page to something
        like *Convert PMAR files*, and add it to the "Process acoustic
        data" nav group alongside the WISPR pages. Fold the short
        WAV↔FLAC section in as a subsection of whichever page makes more
        sense (or its own short page) so it's reachable too.

- [ ] **`map-help.qmd` is a stub with no nav entry**, but it *is* linked
      twice from `mission-planning.qmd` ("For more help setting those
      parameters, see the Map Help page" / "See more on this on the Map
      Help page"). Right now those links dead-end on "More coming soon..."
      Either fill this in before shipping those links, or remove the
      links until it's ready — a linked-to stub reads as broken to a
      first-time user even though it's not technically a 404.

- [ ] **`about.qmd` is unused Quarto scaffold** (literally the default
      "Heading 1 / Regular text" placeholder content, `1 + 1` code chunk
      and all). It's already commented out of the nav — I'd just delete
      the file. No reason to keep dead scaffold in the source.

- [ ] **`wispr-gain-fix.qmd` isn't in the nav** (only reachable via
      callout links from the two conversion pages). This one seems
      *intentional* — it's framed in the text itself as a niche,
      "for posterity" reference rather than core documentation — so I'd
      leave it out of the main nav. Flagging only so it's a conscious
      choice rather than an oversight.

- [ ] **Consider whether `get-started.qmd` should be split.** It
      currently does two jobs: installation (4 different options) and a
      full "Quick Start" walkthrough (config files → folder structure →
      initialize → download basestation files → extract piloting
      params). That's a lot for a first page. A new user reads
      "Installation" and "Quick Start Guide" as fundamentally different
      tasks — one they do once, one they reference every mission. Splitting
      into **"Installation"** and **"Quick start"** (or moving the
      "Quick Start Guide" content into `configuration.qmd` +
      `piloting.qmd`, since it overlaps with both) would make each page
      more scannable and let people bookmark just the part they need.

- [ ] **Naming inconsistency**: the homepage credits **"NOAA's Uncrewed
      Systems Operations Center (UxSOC)"** as the funder, while
      `acknowledgements.qmd` says **"NOAA OMAO Uncrewed Systems Research
      Transition Office Grant."** These may both be accurate (a grant
      program administered by the office), but worth double-checking the
      exact/preferred name and using it consistently in both places —
      this is the kind of thing a funder or JOSS reviewer might notice.

---

## 2. Page-by-page

### `index.qmd` (Home)
- Solid overall — clear, non-jargony opening (good for JOSS's
  non-specialist-reader requirement).
- No content issues found beyond the funder-naming note above.

### `get-started.qmd`
- [ ] **Broken code (would error if copy-pasted):**
  ```matlab
  mkdir(fullfile(CONFIG.path.mission, 'flightStatus'); % where to store status outputs );
  ```
  Misplaced parenthesis — the `mkdir(...)` call itself is never closed
  before the comment starts. Should be:
  ```matlab
  mkdir(fullfile(CONFIG.path.mission, 'flightStatus')); % where to store status outputs
  ```
- [ ] **Truncated comment:** the very next line ends mid-word —
  `mkdir(fullfile(CONFIG.path.mission, 'profiles')); % where to store post-`
- [ ] **Undefined variable**: the "Extract select piloting parameters"
  example uses `path_status`, which is never defined anywhere on this
  page (only `path_bsLocal` is). A reader following top-to-bottom would
  hit an "Undefined variable" error.
- [ ] **Grammar**: "use the *Contribute* button to create pull requests
  so contribute your modifications" — reads as a double "contribute";
  probably meant "...to create pull requests **and** contribute your
  modifications" or simply "...to contribute your modifications."
- [ ] **External link worth checking**: "For more help with GitHub see
  this [Git Started Doc]" points to
  `PIFSC-Protected-Species-Division/PSDOS` — if that repo is private,
  external contributors (and JOSS reviewers) will hit a 404. Worth
  confirming it's public, or swapping for GitHub's own official fork/PR
  docs (which you already link elsewhere).
- [ ] Given the fork/PR walkthrough here (**Option 3**) already largely
  duplicates `CONTRIBUTING.md`/`contribute.qmd`, consider trimming this
  down to a one-line pointer to the Contribute page instead of
  re-explaining the whole workflow a third time.

### `configuration.qmd`
- [ ] **Three broken/empty links** in one sentence: "...interfacing
  with the [basestation](), working with [acoustic]() data outputs, and
  [plotting maps]()" — all three link targets are empty. These should
  point to the relevant sections (`#basestation-configuration-file`,
  the acoustics settings section, and the plotting settings section).
- [ ] **Duplicated word**: "The The position of each plot can also be
  defined..." (Piloting-related plots section).
- [ ] **Dead commented-out content**: the last ~35 lines of the file
  (PMAR/WISPR "conversion configuration file" sections) are entirely
  HTML-commented out, including a `**UNDER CONSTRUCTION**` marker. Since
  this doesn't render, it's invisible to readers — but it's also stale
  now that PMAR conversion config lives in `convert-acoustics.qmd`. Same
  principle as dead code in `.m` files: safe to delete, GitHub history
  preserves it if needed.
- [ ] Related to the structure note above: `convert-acoustics.qmd`
  links here with `configuration.html#pmar-conversion-configuration-file`
  — an anchor that doesn't exist because this section is commented out.
  Fixing this page and that link are the same fix.

### `mission-planning.qmd`
- [ ] **Typo, 2 occurrences**: "Dependecies" → "Dependencies" (also
  appears in `piloting.qmd` and `plotting.qmd` — same typo, 3 files, one
  find-and-replace).
- [ ] **Case-mismatched filename in link text vs. actual link**: text
  reads `ExampleTrackWaypointNames.txt` (capital E) but the link target
  is `exampleTrackWaypointNames.txt` (lowercase e). GitHub URLs are
  case-sensitive, so if the actual filename doesn't match one of these,
  the link is broken — worth a quick check against the real file in
  `example_workflows`.

### `piloting.qmd`
- [ ] **Function name typo (verified against source)**: `downloadBasetationFiles`
  should be `downloadBasestationFiles` (the actual function, confirmed
  in `agate/utils/`). This one's a real trap — someone copy-pasting the
  example gets an "Undefined function" error.
- [ ] **Missing quotes — would error**: `CONFIG = agate(agate_config.cnf);`
  should be `CONFIG = agate('agate_config.cnf');` (confirmed against the
  `agate()` function signature, which expects a string). Every other
  page quotes this correctly except this one and `plotting.qmd`.
- [ ] "Dependecies" typo (see above).

### `mission-processing.qmd`
- [ ] **Function name typo**: `extractPAMSatus` should be
  `extractPAMStatus` (confirmed — the code block two paragraphs later
  correctly calls `extractPAMStatus`, so this is just a prose typo, but
  it's the kind of inconsistency that undermines trust in the docs).
- [ ] **Truncated sentence**: "Use the `calcPAMEffort` function to
  summarize mission acoustic effort... This and the other acoustic
  effort" — sentence just stops. Needs finishing.
- [ ] **Truncated file extension in a comment**: `% save as .mat and .cs`
  should be `.csv`.
- [ ] **Empty section — needs content**: "### Plot multiple glider
  tracks" is a bare header with nothing under it, even though it's
  listed at the top of the page as one of four workflows and has a
  "[Jump to section]" link pointing at it. This is the most visible gap
  on the page since it's promised up front and then not delivered.
- [ ] Broken link to `convert-acoustics.qmd` for PMAR/WAV/FLAC info —
  same underlying issue as the structure note above.

### `convert-acoustics.qmd`
- [ ] Not in nav (see structural note above).
- [ ] WISPR section is stale/duplicate of `convert-wispr.qmd`.
- [ ] Links to `configuration.html#pmar-conversion-configuration-file`,
  which doesn't currently exist (commented out — see `configuration.qmd`
  note above).

### `convert-wispr.qmd`
- No issues found — this is one of the stronger pages on the site:
  clear two-approach structure, good code examples, appropriately
  cross-linked.

### `wispr-calibration.qmd`
- [ ] **Broken image link**: `![](full-set-up.png)` — I checked, this
  file doesn't exist anywhere in `docs/images/` (the other WISPR
  calibration images all live in `docs/images/wispr_calibration/`, so
  this was likely meant to be
  `images/wispr_calibration/full-set-up.png` or similar, just never
  added).
- [ ] **Empty sections — needs content**: "### Record calibration
  signals" and "### Assemble system sensitivity curve" are both bare
  headers with nothing written under them. The page currently walks
  through processing recordings but skips over how to *make* the
  recordings in the first place, and cuts off before explaining how to
  combine the preamp curve with the rest of the system response (which
  is literally goal #2 stated at the top of the page).
- [ ] **Typos**: "univeral" → "universal"; "swithch" → "switch";
  "compatibile" → "compatible."
- Nice touch: linking back to the more detailed Google Doc as the
  source — keep that.

### `plotting.qmd`
- [ ] **Broken link — malformed markdown syntax**: `[configuration
  file](configuration.qmd#optinal-plotting-settings.` — missing closing
  parenthesis on the link *and* a typo ("optinal" → "optional") in the
  anchor. Likely renders as broken/literal text rather than a working
  link.
- [ ] **Missing quotes — would error**: same `agate(agate_config.cnf)`
  issue as `piloting.qmd`.
- [ ] **Likely typo**: `CONFIG.latLim = [40.25 45.00];` — probably
  missing `.map`, i.e. should be `CONFIG.map.latLim` (the very next line
  correctly uses `CONFIG.map.lonLim`).
- [ ] **Empty sections — needs content**, all under "Mission summary
  plots" and "Analysis plots": *Final trackline map*, *Dive profile*,
  *Sound speed profile* (this one seems like an oversight — there's a
  whole worked example of `plotSoundSpeedProfile` already written in
  `mission-processing.qmd`, so this section could likely just point
  there or reuse that example), and *Cetacean event maps*. This is the
  single biggest concentration of "needs expansion" content on the
  whole site — four promised-but-empty sections in one page.
- [ ] "Dependecies" typo (see above).

### `contribute.qmd`
- [ ] Still needs the cross-link callout we drafted earlier pointing to
  `CONTRIBUTING.md` on GitHub — looks like it hasn't been added to the
  source yet:
  ```markdown
  ::: {.callout-note}
  This page has the full guide to contributing to `agate`. For a shorter
  quick-reference version, see [`CONTRIBUTING.md`](https://github.com/sfregosi/agate/blob/main/docs/CONTRIBUTING.md)
  in the GitHub repository.
  :::
  ```
- Otherwise clean — no other issues.

### `acknowledgements.qmd`
- Short and clean. Only the funder-naming consistency note above.

### `map-help.qmd`
- Stub — see structural note above.

### `wispr-gain-fix.qmd`
- [ ] Minor tone note: "(should be fixed now??)" reads as an unresolved
  internal note rather than finished documentation — worth either
  confirming and stating plainly, or removing the aside if it's not
  actually known.
- Otherwise thorough and clearly written for its (niche) purpose.

### `about.qmd`
- Delete (see structural note above).

---

## Suggested priority order

1. **Fix the four things that actually break for a user**: the two
   unquoted-string code errors, the two misnamed-function typos, and
   the malformed/broken links. These are quick, high-value fixes since
   they'll actively cost someone time if hit while following along.
2. **Resolve the `convert-acoustics.qmd` orphan** — this is blocking
   real content (PMAR conversion) from being discoverable at all.
3. **Fill or unlink** the empty sections in `plotting.qmd`,
   `mission-processing.qmd`, and `wispr-calibration.qmd` — especially
   "Plot multiple glider tracks" and "Sound speed profile," which look
   like straightforward fills given existing content elsewhere.
4. **Cleanup pass**: typos, dead commented-out blocks, `about.qmd`
   deletion, funder-name consistency — lower stakes, good candidates
   for a single tidy-up session.
5. **Structural**: decide on the `get-started.qmd` split and whether
   `map-help.qmd` gets built out or unlinked.
