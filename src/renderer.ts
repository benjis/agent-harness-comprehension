import { access, mkdir, writeFile } from "node:fs/promises";
import { dirname, isAbsolute, resolve } from "node:path";
import type { ComprehensionLedger } from "./ledger.ts";
import type { LedgerEvent, SemanticLedgerEvent } from "./types.ts";

export interface ResolvedSemanticEvent {
	event: SemanticLedgerEvent;
	current: boolean;
}

export function resolveSemanticEvents(events: LedgerEvent[]): ResolvedSemanticEvent[] {
	const semantic = events.filter((event): event is SemanticLedgerEvent => event.family === "semantic");
	const supersededIds = new Set(semantic.flatMap((event) => event.supersedes ?? []));
	return semantic.map((event) => ({
		event,
		current: event.status !== "refuted" && event.status !== "superseded" && !supersededIds.has(event.id),
	}));
}

function detailLines(event: SemanticLedgerEvent): string[] {
	const lines = [`- **${event.type}** \`${event.id}\`: ${event.summary}`];
	if (event.status) lines.push(`  - Status: ${event.status}`);
	if (event.because?.length) lines.push(`  - Because: ${event.because.join("; ")}`);
	if (event.evidence?.length) lines.push(`  - Evidence: ${event.evidence.join("; ")}`);
	if (event.supersedes?.length) lines.push(`  - Supersedes: ${event.supersedes.map((id) => `\`${id}\``).join(", ")}`);
	return lines;
}

function section(title: string, events: SemanticLedgerEvent[], empty: string): string[] {
	return [`## ${title}`, "", ...(events.length ? events.flatMap(detailLines) : [`_${empty}_`]), ""];
}

async function fileLine(cwd: string, file: string): Promise<string> {
	const absolutePath = isAbsolute(file) ? file : resolve(cwd, file);
	try {
		await access(absolutePath);
		return `- \`${file}\``;
	} catch {
		return `- \`${file}\` — missing at render time`;
	}
}

export async function renderMentalModel(events: LedgerEvent[], cwd: string): Promise<string> {
	const resolved = resolveSemanticEvents(events);
	const current = resolved.filter((item) => item.current).map((item) => item.event);
	const historical = resolved.filter((item) => !item.current).map((item) => item.event);
	const byType = (source: SemanticLedgerEvent[], types: SemanticLedgerEvent["type"][]) =>
		source.filter((event) => types.includes(event.type));

	const currentImplementation = byType(current, ["evidence", "decision", "revision"]);
	const decisions = byType(current, ["decision", "tradeoff"]);
	const revisions = [
		...byType(current, ["revision", "failure"]),
		...historical,
		...byType(current, ["alternative"]).filter((event) => event.status !== "active"),
	];
	const files = [...new Set(current.flatMap((event) => event.relatedFiles ?? []))];
	const symbols = [...new Set(current.flatMap((event) => event.relatedSymbols ?? []))];
	const executionCount = events.filter((event) => event.family === "execution").length;

	const lines = [
		"# Mental Model",
		"",
		"> Generated deterministically from the append-only comprehension ledger.",
		"> Current truth includes active/confirmed records not superseded by a later record. Final source remains authoritative.",
		"",
		...section("Goal", byType(current, ["goal"]), "No goal checkpoint recorded."),
		...section(
			"Current Implementation (Current Truth)",
			currentImplementation,
			"No current implementation checkpoint recorded.",
		),
		...section("Important Decisions (Current Truth)", decisions, "No current decision checkpoint recorded."),
		...section(
			"Revisions and Failed Paths (Historical / Rejected / Superseded)",
			revisions,
			"No revision or failed path recorded.",
		),
		...section(
			"Constraints and Invariants",
			byType(current, ["constraint", "invariant"]),
			"No current constraint or invariant recorded.",
		),
		...section("Validation", byType(current, ["validation"]), "No semantic validation checkpoint recorded."),
		"## Where to Look Next",
		"",
	];

	if (files.length === 0 && symbols.length === 0) {
		lines.push("_No current file or symbol references recorded._");
	} else {
		for (const file of files) lines.push(await fileLine(cwd, file));
		for (const symbol of symbols) lines.push(`- Symbol: \`${symbol}\``);
	}
	lines.push(
		"",
		"## Ledger Coverage",
		"",
		`- ${events.length} total events`,
		`- ${executionCount} execution events`,
		`- ${resolved.length} semantic events`,
		"",
	);
	return `${lines.join("\n")}\n`;
}

export async function writeMentalModel(ledger: ComprehensionLedger, cwd: string, outputPath: string): Promise<void> {
	const content = await renderMentalModel(await ledger.readAll(), cwd);
	await mkdir(dirname(outputPath), { recursive: true });
	await writeFile(outputPath, content, "utf8");
}
