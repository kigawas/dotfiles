/**
 * Idle compaction: compacts a session once it has been idle for 55 minutes.
 *
 * The 1-hour prompt cache expires an hour after the last request. Compacting
 * just before that means the next resume re-writes a smaller context. Small
 * sessions are skipped, since compacting them loses detail for little saving.
 */
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const IDLE_MS = 55 * 60 * 1000;
const MIN_TOKENS = 100_000;

export default function (pi: ExtensionAPI) {
	let timer: ReturnType<typeof setTimeout> | undefined;
	let latest: ExtensionContext | undefined;

	const disarm = () => {
		if (timer !== undefined) clearTimeout(timer);
		timer = undefined;
	};

	// Restart the 55-minute clock from now. Each event passes a fresh ctx,
	// because a session replacement invalidates the old one.
	const arm = (ctx: ExtensionContext) => {
		latest = ctx;
		disarm();
		timer = setTimeout(() => {
			timer = undefined;
			const idle = latest;
			if (!idle || !idle.isIdle() || idle.hasPendingMessages()) return;
			const tokens = idle.getContextUsage()?.tokens ?? 0;
			if (tokens < MIN_TOKENS) return;
			idle.compact();
		}, IDLE_MS);
	};

	pi.on("session_start", (_event, ctx) => arm(ctx));
	pi.on("agent_settled", (_event, ctx) => arm(ctx));
	pi.on("session_shutdown", () => {
		disarm();
		latest = undefined;
	});
}
