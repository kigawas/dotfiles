/**
 * Runs your own `!` and `!!` commands in zsh, with ~/.zshrc loaded, so zsh
 * aliases and functions such as `gst` and `gp` work. The model's bash tool is
 * unchanged.
 *
 * zsh reads a line's aliases before it runs that line, so aliases defined by
 * the `source` line can't be used on the same line. `eval` re-reads the
 * command after .zshrc has loaded.
 */
import { createLocalBashOperations, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

const ZSH = "/bin/zsh";

export default function (pi: ExtensionAPI) {
	const zsh = createLocalBashOperations({ shellPath: ZSH });

	pi.on("user_bash", () => ({
		operations: {
			exec: (command, cwd, options) =>
				zsh.exec(
					`source ~/.zshrc >/dev/null 2>&1\neval ${shellQuote(command)}`,
					cwd,
					options,
				),
		},
	}));
}

// Single-quote a string for zsh: close the quote, add an escaped quote, reopen.
function shellQuote(s: string): string {
	return `'${s.replaceAll("'", `'\\''`)}'`;
}
