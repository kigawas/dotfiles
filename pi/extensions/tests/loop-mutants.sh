#!/bin/bash
# Breaks loop.ts one way at a time and runs the fast tests on each copy. Every
# mutant must make a test fail; a survivor is a behaviour no test pins. An entry
# whose text is not in loop.ts exactly once is reported as broken: update it
# with the code. Run by `run.sh --mutants` from its temp copy.
set -u
cd "$(dirname "$0")"
mkdir -p mut
[ -e mut/node_modules ] || ln -s ../node_modules mut/node_modules
cp loop-*.test.ts loop-harness.ts mut/
tests=$(cd mut && ls loop-*.test.ts)
bad=0

mutant() {
	cp loop.ts mut/loop.ts
	if ! perl -e '
		my ($f, $from, $to) = @ARGV;
		local $/; open my $h, "<", $f or die; my $s = <$h>; close $h;
		my $n = () = $s =~ /\Q$from\E/g;
		exit 3 if $n != 1;
		$s =~ s/\Q$from\E/$to/;
		open $h, ">", $f or die; print $h $s; close $h' mut/loop.ts "$2" "$3"; then
		echo "BROKEN   $1: its text is not in loop.ts exactly once"
		bad=1
		return
	fi
	out=$(cd mut && node --test $tests 2>&1)
	rc=$?
	failed=$(printf '%s\n' "$out" | grep -E '^✖ ' | grep -v 'failing tests' | sed 's/ ([0-9.]*ms)$//' | sort -u | tr '\n' ';')
	if [ $rc -eq 1 ] && [ -n "$failed" ]; then
		echo "killed   $1 :: $failed"
	else
		echo "SURVIVED $1 (exit $rc)"
		bad=1
	fi
}

mutant "no Math.max on checked" 'job.checked = Math.max(job.checked, slot);' 'job.checked = slot;'
mutant "restore from the session_start minute" 'checked: j.checked ?? minuteOf(now), due: j.due' 'checked: minuteOf(now)'
mutant "no save on reload shutdown" 'if (event.reason === "reload" && jobs.length) save();' ''
mutant "no hold after Esc" 'holdUntil = Date.now() + HOLD_AFTER_ESC_MS;' ''
mutant "no pending-message guard" ' || ctx.hasPendingMessages()' ''
mutant "newest firing first" '(a.due ?? 0) - (b.due ?? 0)' '(b.due ?? 0) - (a.due ?? 0)'
mutant "a new job checks its own minute" 'expiresAt, checked: minuteOf(now) }' 'expiresAt, checked: minuteOf(now) - MINUTE }'
mutant "only a bare * stars a day field" 'anyDom: parts[2].startsWith("*")' 'anyDom: parts[2] === "*"'
mutant "duplicate prompts allowed" 'if (twin) throw' 'if (false && twin) throw'
mutant "a one-shot is kept" 'if (!job.recurring) {' 'if (false) {'
mutant "no save after the lapse warning" '		} else if (saved.length) {
			save();' '		} else if (saved.length) {'
mutant "/loop delete without an id falls through" 'if (!id) throw new Error("usage: /loop delete <id|all>");' ''
mutant "7 is not Sunday" 'if (dow.has(7)) dow.add(0);' ''
mutant "no expiry" 'const expired = jobs.filter((j) => now >= j.expiresAt);' 'const expired = jobs.filter((j) => false);'
mutant "either day field when one is starred" 'return c.anyDom || c.anyDow ? dom && dow : dom || dow;' 'return dom || dow;'
mutant "the created minute itself can match" 'for (let t = minuteOf(after) + MINUTE; t <= until; t += MINUTE) {' 'for (let t = minuteOf(after); t <= until; t += MINUTE) {'

exit $bad
