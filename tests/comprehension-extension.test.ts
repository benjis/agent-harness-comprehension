import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { Value } from "typebox/value";
import { afterEach, describe, expect, it, vi } from "vitest";
import { createComprehensionExtension } from "../src/extension.ts";
import { ComprehensionLedger } from "../src/ledger.ts";
import { renderMentalModel, resolveSemanticEvents } from "../src/renderer.ts";
import {
	createExecutionEvent,
	createSemanticEvent,
	type SemanticEventInput,
	SemanticEventInputSchema,
} from "../src/types.ts";
import type {
	ExtensionAPI,
	ExtensionContext,
	RegisteredCommand,
	ToolDefinition,
} from "@earendil-works/pi-coding-agent";

type EventHandler = (event: Record<string, unknown>, ctx: ExtensionContext) => Promise<unknown> | unknown;

const tempDirectories: string[] = [];

afterEach(async () => {
	await Promise.all(tempDirectories.splice(0).map((directory) => rm(directory, { recursive: true, force: true })));
});

async function temporaryDirectory(): Promise<string> {
	const directory = await mkdtemp(join(tmpdir(), "pi-comprehension-"));
	tempDirectories.push(directory);
	return directory;
}

function setupExtension(cwd: string) {
	const handlers = new Map<string, EventHandler>();
	const commands = new Map<string, Omit<RegisteredCommand, "name" | "sourceInfo">>();
	let tool: ToolDefinition<typeof SemanticEventInputSchema> | undefined;
	const api = {
		on(name: string, handler: EventHandler) {
			handlers.set(name, handler);
		},
		registerTool(definition: ToolDefinition) {
			if (definition.name === "record_comprehension_event") {
				tool = definition as ToolDefinition<typeof SemanticEventInputSchema>;
			}
		},
		registerCommand(name: string, command: Omit<RegisteredCommand, "name" | "sourceInfo">) {
			commands.set(name, command);
		},
	} as unknown as ExtensionAPI;
	createComprehensionExtension(api, ".pi");

	const notify = vi.fn();
	const ctx = {
		cwd,
		mode: "print",
		hasUI: false,
		ui: { notify },
		sessionManager: {
			getSessionId: () => "test-session",
		},
		waitForIdle: async () => {},
	} as unknown as ExtensionContext;

	return {
		commands,
		ctx,
		handlers,
		notify,
		getTool() {
			if (!tool) throw new Error("record_comprehension_event was not registered");
			return tool;
		},
		async emit(name: string, event: Record<string, unknown>) {
			const handler = handlers.get(name);
			if (!handler) throw new Error(`Missing handler: ${name}`);
			await handler(event, ctx);
		},
	};
}

describe("comprehension extension", () => {
	it("validates the semantic event schema", () => {
		expect(Value.Check(SemanticEventInputSchema, { type: "decision", summary: "Use an extension" })).toBe(true);
		expect(Value.Check(SemanticEventInputSchema, { type: "thought", summary: "Unsupported" })).toBe(false);
		expect(Value.Check(SemanticEventInputSchema, { type: "decision" })).toBe(false);
		expect(Value.Check(SemanticEventInputSchema, { type: "decision", summary: "Valid", unexpected: true })).toBe(
			false,
		);
	});

	it("appends referenceable events without replacing earlier lines", async () => {
		const directory = await temporaryDirectory();
		const ledger = new ComprehensionLedger(join(directory, "events.jsonl"));
		const first = createSemanticEvent(
			{ type: "hypothesis", summary: "Core changes may be required" },
			{ createId: () => "first", now: () => new Date("2026-01-01T00:00:00.000Z") },
		);
		await ledger.append(first);
		const firstWrite = await readFile(ledger.path, "utf8");
		const second = createSemanticEvent(
			{ type: "revision", summary: "Extension seams are sufficient", supersedes: [first.id] },
			{ createId: () => "second", now: () => new Date("2026-01-01T00:00:01.000Z") },
		);
		await ledger.append(second);

		const finalWrite = await readFile(ledger.path, "utf8");
		expect(first.id).toBe("sem-first");
		expect(finalWrite.startsWith(firstWrite)).toBe(true);
		expect((await ledger.readAll()).map((event) => event.id)).toEqual(["sem-first", "sem-second"]);
	});

	it("separates current truth from superseded history in the renderer", async () => {
		const directory = await temporaryDirectory();
		await writeFile(join(directory, "current.ts"), "export {};\n");
		const oldDecision = createSemanticEvent(
			{ type: "decision", summary: "Modify core", relatedFiles: ["missing.ts"] },
			{ createId: () => "old" },
		);
		const currentDecision = createSemanticEvent(
			{
				type: "decision",
				summary: "Implement as an extension",
				status: "confirmed",
				supersedes: [oldDecision.id],
				relatedFiles: ["current.ts"],
			},
			{ createId: () => "current" },
		);
		const execution = createExecutionEvent("agent_started", "Agent run started", undefined, {
			createId: () => "execution",
		});

		const resolved = resolveSemanticEvents([oldDecision, currentDecision, execution]);
		expect(resolved.map(({ event, current }) => [event.id, current])).toEqual([
			["sem-old", false],
			["sem-current", true],
		]);
		const markdown = await renderMentalModel([oldDecision, currentDecision, execution], directory);
		expect(markdown).toContain("Current Implementation (Current Truth)");
		expect(markdown).toContain("Implement as an extension");
		expect(markdown).toContain("Historical / Rejected / Superseded");
		expect(markdown).toContain("Modify core");
		expect(markdown).toContain("`current.ts`");
		expect(markdown).not.toContain("`missing.ts` — missing at render time");
	});

	it("registers the semantic tool, commands, and deterministic lifecycle capture", async () => {
		const directory = await temporaryDirectory();
		const extension = setupExtension(directory);
		expect(extension.getTool().name).toBe("record_comprehension_event");
		expect(extension.commands.has("comprehension")).toBe(true);
		expect(extension.commands.has("comprehension-status")).toBe(true);

		await extension.emit("session_start", { type: "session_start", reason: "startup" });
		await extension.emit("agent_start", { type: "agent_start" });
		await extension.emit("tool_execution_start", {
			type: "tool_execution_start",
			toolCallId: "call-1",
			toolName: "read",
			args: { path: "src/index.ts" },
		});
		await extension.emit("tool_execution_end", {
			type: "tool_execution_end",
			toolCallId: "call-1",
			toolName: "read",
			result: { content: [{ type: "text", text: "raw tool output must not be persisted" }] },
			isError: false,
		});
		await extension.emit("agent_settled", { type: "agent_settled" });

		const ledgerPath = join(directory, ".pi", "comprehension", "test-session", "events.jsonl");
		const ledger = new ComprehensionLedger(ledgerPath);
		const events = await ledger.readAll();
		expect(events.map((event) => event.type)).toEqual([
			"session_started",
			"agent_started",
			"tool_started",
			"tool_completed",
			"agent_settled",
		]);
		expect(events[2].summary).toBe("Tool read started for src/index.ts");
		expect(await readFile(ledgerPath, "utf8")).not.toContain("raw tool output must not be persisted");
		expect(
			await readFile(join(directory, ".pi", "comprehension", "test-session", "mental-model.md"), "utf8"),
		).toContain("# Mental Model");
	});

	it("records semantic events and rejects blank checkpoints before appending", async () => {
		const directory = await temporaryDirectory();
		const extension = setupExtension(directory);
		await extension.emit("session_start", { type: "session_start", reason: "startup" });
		const tool = extension.getTool();
		const valid: SemanticEventInput = {
			type: "decision",
			summary: "Use public extension lifecycle hooks",
			evidence: ["The API exposes tool execution events"],
		};
		const result = await tool.execute("semantic-1", valid, undefined, undefined, extension.ctx);
		expect(result.details).toMatchObject({ recorded: true, eventId: expect.stringMatching(/^sem-/) });

		const ledger = new ComprehensionLedger(join(directory, ".pi", "comprehension", "test-session", "events.jsonl"));
		const countBeforeInvalid = (await ledger.readAll()).length;
		await expect(
			tool.execute("semantic-2", { type: "decision", summary: "   " }, undefined, undefined, extension.ctx),
		).rejects.toThrow("summary must not be blank");
		expect(await ledger.readAll()).toHaveLength(countBeforeInvalid);
	});
});
