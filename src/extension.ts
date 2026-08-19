import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { ComprehensionLedger } from "./ledger.ts";
import { writeMentalModel } from "./renderer.ts";
import {
	createExecutionEvent,
	createSemanticEvent,
	type ExecutionEventData,
	type ExecutionEventType,
	SemanticEventInputSchema,
} from "./types.ts";

interface ExtensionState {
	cwd: string;
	ledger: ComprehensionLedger;
	mentalModelPath: string;
	renderError?: string;
}

interface ComprehensionToolDetails {
	recorded: boolean;
	eventId?: string;
	ledgerPath?: string;
}

function stringProperty(value: unknown, key: string): string | undefined {
	if (!value || typeof value !== "object" || !(key in value)) return undefined;
	const property = (value as Record<string, unknown>)[key];
	return typeof property === "string" ? property : undefined;
}

function toolTarget(args: unknown): string | undefined {
	return stringProperty(args, "path");
}

function toolSummary(toolName: string, phase: "started" | "completed" | "failed", args?: unknown): string {
	const target = toolTarget(args);
	return `Tool ${toolName} ${phase}${target ? ` for ${target}` : ""}`;
}

export function createComprehensionExtension(pi: ExtensionAPI, configDirectoryName: string) {
	let state: ExtensionState | undefined;

	const recordExecution = async (
		type: ExecutionEventType,
		summary: string,
		data?: ExecutionEventData,
	): Promise<void> => {
		await state?.ledger.append(createExecutionEvent(type, summary, data));
	};

	const render = async (): Promise<boolean> => {
		if (!state) return false;
		try {
			await writeMentalModel(state.ledger, state.cwd, state.mentalModelPath);
			state.renderError = undefined;
			return true;
		} catch (error) {
			state.renderError = error instanceof Error ? error.message : String(error);
			return false;
		}
	};

	pi.on("session_start", async (event, ctx) => {
		const sessionId = ctx.sessionManager.getSessionId().replace(/[^a-zA-Z0-9_-]/g, "_");
		const directory = join(ctx.cwd, configDirectoryName, "comprehension", sessionId);
		state = {
			cwd: ctx.cwd,
			ledger: new ComprehensionLedger(join(directory, "events.jsonl")),
			mentalModelPath: join(directory, "mental-model.md"),
		};
		await recordExecution("session_started", `Session started (${event.reason})`, {
			reason: event.reason,
			sessionId: ctx.sessionManager.getSessionId(),
		});
	});

	pi.on("agent_start", async () => {
		await recordExecution("agent_started", "Agent run started");
	});

	pi.on("turn_start", async (event) => {
		await recordExecution("turn_started", `Turn ${event.turnIndex} started`, { turnIndex: event.turnIndex });
	});

	pi.on("turn_end", async (event) => {
		await recordExecution("turn_ended", `Turn ${event.turnIndex} ended`, {
			turnIndex: event.turnIndex,
			toolResultCount: event.toolResults.length,
		});
	});

	pi.on("tool_execution_start", async (event) => {
		const target = toolTarget(event.args);
		await recordExecution("tool_started", toolSummary(event.toolName, "started", event.args), {
			toolCallId: event.toolCallId,
			toolName: event.toolName,
			...(target ? { target } : {}),
		});
	});

	pi.on("tool_execution_end", async (event) => {
		await recordExecution(
			event.isError ? "tool_failed" : "tool_completed",
			toolSummary(event.toolName, event.isError ? "failed" : "completed"),
			{ toolCallId: event.toolCallId, toolName: event.toolName },
		);
	});

	pi.on("agent_settled", async () => {
		await recordExecution("agent_settled", "Agent run settled");
		await render();
	});

	pi.on("session_shutdown", async (event) => {
		await recordExecution("session_shutdown", `Session shutdown (${event.reason})`, { reason: event.reason });
		await render();
	});

	pi.registerTool<typeof SemanticEventInputSchema, ComprehensionToolDetails>({
		name: "record_comprehension_event",
		label: "Record Comprehension Event",
		description:
			"Publish one concise, decision-relevant semantic checkpoint to the append-only comprehension ledger. Record declared conclusions and transitions only; never include private chain-of-thought or raw secrets. Later events may reference or supersede IDs returned by this tool.",
		promptSnippet:
			"Record material hypotheses, evidence, decisions, failures, revisions, invariants, and validations",
		promptGuidelines: [
			"Use record_comprehension_event for material conclusions or direction changes, not routine narration or every tool call.",
			"Use record_comprehension_event to connect revisions and decisions to earlier event IDs with supersedes, because, and evidence.",
			"Never put private chain-of-thought, raw prompts, credentials, or raw tool output in record_comprehension_event.",
		],
		parameters: SemanticEventInputSchema,
		executionMode: "sequential",
		async execute(_toolCallId, params) {
			if (!state) {
				return {
					content: [{ type: "text", text: "Comprehension ledger is unavailable before session_start." }],
					details: { recorded: false },
				};
			}
			const event = createSemanticEvent(params);
			const recorded = await state.ledger.append(event);
			return {
				content: [
					{
						type: "text",
						text: recorded
							? `Recorded ${event.type} checkpoint ${event.id}.`
							: `Checkpoint ${event.id} was not recorded; execution may continue.`,
					},
				],
				details: { recorded, eventId: event.id, ledgerPath: state.ledger.path },
			};
		},
	});

	pi.registerCommand("comprehension", {
		description: "Render the current session comprehension mental model",
		handler: async (_args, ctx) => {
			await ctx.waitForIdle();
			const rendered = await render();
			if (!state) {
				ctx.ui.notify("Comprehension ledger is not initialized", "error");
			} else if (rendered) {
				ctx.ui.notify(`Mental model: ${state.mentalModelPath}`, "info");
			} else {
				ctx.ui.notify(`Mental-model render failed: ${state.renderError ?? "unknown error"}`, "warning");
			}
		},
	});

	pi.registerCommand("comprehension-status", {
		description: "Show comprehension event counts and artifact paths",
		handler: async (_args, ctx) => {
			if (!state) {
				ctx.ui.notify("Comprehension ledger is not initialized", "error");
				return;
			}
			const events = await state.ledger.readAll();
			const counts = new Map<string, number>();
			for (const event of events) counts.set(event.type, (counts.get(event.type) ?? 0) + 1);
			const countText = [...counts.entries()]
				.sort(([left], [right]) => left.localeCompare(right))
				.map(([type, count]) => `${type}=${count}`)
				.join(", ");
			const error = state.ledger.lastError ?? state.renderError;
			ctx.ui.notify(
				`${events.length} events${countText ? ` (${countText})` : ""}\nLedger: ${state.ledger.path}\nMental model: ${state.mentalModelPath}${error ? `\nLast error: ${error}` : ""}`,
				error ? "warning" : "info",
			);
		},
	});
}

export function getComprehensionPaths(
	ctx: ExtensionContext,
	configDirectoryName: string,
): { ledgerPath: string; mentalModelPath: string } {
	const sessionId = ctx.sessionManager.getSessionId().replace(/[^a-zA-Z0-9_-]/g, "_");
	const directory = join(ctx.cwd, configDirectoryName, "comprehension", sessionId);
	return {
		ledgerPath: join(directory, "events.jsonl"),
		mentalModelPath: join(directory, "mental-model.md"),
	};
}
