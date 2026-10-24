// Live test that loop.ts jobs survive a real /reload. It runs the extension
// beside a copy with the restore step removed: the copy must stop firing, which
// shows the reload really happened and the old runtime's timers are gone.
// About 3 minutes. Run by `run.sh --live` from its temp copy.
import { spawn } from "node:child_process";
import fs from "node:fs";
const here = import.meta.dirname;
const MODEL = process.env.LOOP_TEST_MODEL ?? "magpie/anthropic/claude-haiku-5-5";
const ts = () => new Date().toTimeString().slice(0, 8);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const text = (m) => typeof m.content === "string" ? m.content : (m.content || []).filter((c) => c.type === "text").map((c) => c.text).join(" ");

const RESTORE = "jobs.push({ ...j, checked: j.checked ?? minuteOf(now), due: j.due });";
const source = fs.readFileSync(`${here}/loop.ts`, "utf8");
if (source.split(RESTORE).length !== 2) throw new Error("the restore line is not in loop.ts exactly once; update RESTORE");
fs.mkdirSync(`${here}/mut-reload`, { recursive: true });
fs.writeFileSync(`${here}/mut-reload/loop.ts`, source.replace(RESTORE, "void j;"));
if (!fs.existsSync(`${here}/mut-reload/node_modules`)) fs.symlinkSync("../node_modules", `${here}/mut-reload/node_modules`);

async function run(name, ext) {
	const p = spawn("pi", ["--mode", "rpc", "--session-dir", `${here}/sessions-${name}`, "--model", MODEL,
		"--no-extensions", "--no-skills", "--no-context-files", "--no-prompt-templates", "--no-mcp", "-e", ext, "-e", `${here}/reload-helper.ts`], { cwd: here, stdio: ["pipe", "pipe", "pipe"] });
	const fires = [], notes = []; let buf = "";
	p.stdout.on("data", (d) => { buf += d; let i; while ((i = buf.indexOf("\n")) >= 0) { const l = buf.slice(0, i); buf = buf.slice(i + 1); let r; try { r = JSON.parse(l); } catch { continue; }
		if (r.type === "message_end" && r.message?.role === "user" && text(r.message).startsWith("[loop ")) { fires.push(Date.now()); console.log(`${ts()} [${name}] FIRE ${text(r.message).split("\n")[0]}`); }
		if (r.type === "extension_ui_request" && r.method === "notify") { notes.push(r.message); console.log(`${ts()} [${name}] notify: ${r.message.split("\n")[0]}`); } } });
	const send = (message) => p.stdin.write(JSON.stringify({ type: "prompt", message }) + "\n");
	await sleep(3000);
	send("/loop * * * * * Reply with exactly: tick");
	const deadline = Date.now() + 90000;
	while (fires.length < 1 && Date.now() < deadline) await sleep(250);
	if (fires.length < 1) { p.stdin.end(); console.log(`${ts()} [${name}] never fired`); return { reloaded: false, after: -1 }; }
	await sleep(3000);
	send("/test-reload");
	await sleep(3000);
	const reloaded = notes.includes("session_start:reload");
	const n = fires.length;
	await sleep(Math.max(0, 60000 - (Date.now() % 60000)) + 65000); // two minute boundaries
	const after = fires.length - n;
	p.stdin.end();
	console.log(`${ts()} [${name}] reloaded=${reloaded} firings after reload=${after}`);
	return { reloaded, after };
}

const [real, mut] = await Promise.all([run("real", `${here}/loop.ts`), run("mut", `${here}/mut-reload/loop.ts`)]);
const ok1 = real.reloaded && real.after === 2;
const ok2 = mut.reloaded && mut.after === 0;
console.log(`${ok1 ? "PASS" : "FAIL"} reloaded, kept firing once a minute`);
console.log(`${ok2 ? "PASS" : "FAIL"} without the restore nothing fires after reload, so the test sees reloads`);
process.exit(ok1 && ok2 ? 0 : 1);
