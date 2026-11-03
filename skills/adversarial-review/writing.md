# Writing scope

The attack checklist for a diff that is a document: a guide, an ADR, a skill, an
`AGENTS.md`, a README, book prose, footnotes, a bibliography, or a translation.
Read it with [REVIEWER.md](REVIEWER.md), which it extends. A document asserts
facts, and **those assertions are the attack surface**, not the prose. Review the
prose only where the brief asks for it.

## Claims

Verify each claim at its source: `file:line` for code, the installed package for
library behaviour, `gh` for issues and PRs, the work itself at its page or URL
for a historical or scholarly fact. A claim about how a tool behaves (git, gh, a
package manager, a shell) is settled by running it in a scratch directory under
`/tmp`, deleted afterwards, not by memory or its docs. Every cited test name must
exist verbatim in the file it is cited under; script the check.

- **Sources**: read each source at the cited place, not a summary, a search
  snippet or memory. Use the repository's local copies first, then the web: your
  web tools, or `curl` with a browser User-Agent. Name the edition, page or URL
  you read.
- **Quotations**: word for word against the original, with every omission marked
  and punctuation at the closing quote as the house rule sets. Confirm italics on
  a page image, since text layers and web captures often drop them. A quotation stays with its speaker:
  what one person reports another saying is not the second person's sentence.
- **Absolutes**: every *never*, *cannot*, *always*, *only* and *first* is a claim
  the source must hold or the sentence must qualify. Look for the counterexample.
- **Details**: dates, numbers, names, titles and places, each against its
  source. A citation's author, title, imprint and pages match the volume actually
  consulted.
- **Severity** is what the claim would cost if a reader acted on it, or if it
  went to print. A control described as stronger than it is, or a gap described
  as open when it is closed, is worse than no description, because the next
  reader trusts it.

Skip rewordings that would merely read better.

## Documents agents execute

A skill or an `AGENTS.md` is followed literally, so its commands are claims too:

- **Every command example obeys the document's own rules.** An example that
  breaks a rule stated a few lines above is the one the agent copies.
- **Every command stands alone.** Check each for state it assumes from an earlier
  call, such as a working directory or an exported variable; an agent's shell
  tool may start a fresh shell per call.
- **A rule repeated across sibling files holds in each.** A fix applied to one
  file and not its sibling leaves the two disagreeing.

## Prose

When the brief asks for a review of style or craft:

- **Protect first.** Name the figures, cadences and deliberate repetitions that
  work, so a later hand does not smooth them away. A repeated word or image can
  be load-bearing: before proposing a cut, look for the line that depends on it.
- **The splice test.** Read every proposed revision inside its sentence and
  paragraph. Check for duplication with surviving text, an echo in the next
  sentence, a limp remainder, footnote markers or italics lost with the deleted
  words, each verb keeping the subject its source gives, and pronouns in the next
  sentence still finding their nouns.
- **The record as it stands.** A revision uses only the facts the text and its
  sources already carry. Anything more goes under "worth verifying".
- **The lightest fix.** A deletion beats a replacement when it resolves the
  issue.
- **The neighbours.** A passage can contradict, repeat or spend the payoff of
  another section or file. Read the neighbours before you finish.
- **Relevance.** Where the brief gives a thesis, each paragraph serves it, or it
  is a candidate cut.

## Translations

- Check against the original, paragraph by paragraph: everything rendered,
  nothing added, and no shift in meaning, register or speaker.
- The house glossary and earlier chapters fix names, terms and recurring words.
- A later correction to the original reaches every translation of it.
- A word can be right in the source language and wrong in the target, such as a
  false friend or an idiom read literally.

## Output additions

- **A verdict per item** the brief lists: `KEEP`, `FIX` or `RULE-CALL`. Each
  `FIX` gives the exact old and new strings, ready for an edit tool. Use
  `RULE-CALL` where two house rules or style sources point different ways: say
  which reading the change applies, and leave the choice to the author.
- **A verdict per claim** when checking facts: verified (with the source and its
  locator), contradicted (with the source's own words), or unverifiable (with
  what you searched).
- The overall `SHIP` / `FIX-FIRST` / `REWORK` verdict still leads the report.
