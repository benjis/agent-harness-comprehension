import { randomUUID } from "node:crypto";
import { StringEnum } from "@earendil-works/pi-ai";
import type { Static } from "typebox";
import { Type } from "typebox";

export const SEMANTIC_EVENT_TYPES = [
	"goal",
	"hypothesis",
	"evidence",
	"decision",
	"alternative",
	"failure",
	"revision",
	"constraint",
	"tradeoff",
	"invariant",
	"validation",
] as const;

export const SEMANTIC_EVENT_STATUSES = ["active", "confirmed", "refuted", "superseded"] as const;

export const EXECUTION_EVENT_TYPES = [
	"session_started",
	"agent_started",
	"turn_started",
	"turn_ended",
	"tool_started",
	"tool_completed",
	"tool_failed",
	"agent_settled",
	"session_shutdown",
] as const;

export type SemanticEventType = (typeof SEMANTIC_EVENT_TYPES)[number];
export type SemanticEventStatus = (typeof SEMANTIC_EVENT_STATUSES)[number];
export type ExecutionEventType = (typeof EXECUTION_EVENT_TYPES)[number];
export type ExecutionEventData = Record<string, string | number | boolean | null>;

const compactString = (description: string) => Type.String({ description, minLength: 1, maxLength: 500 });
const compactStringArray = (description: string) =>
	Type.Optional(Type.Array(compactString(description), { maxItems: 20 }));

export const SemanticEventInputSchema = Type.Object(
	{
		type: StringEnum(SEMANTIC_EVENT_TYPES),
		summary: compactString("A concise declared conclusion or transition, not private reasoning"),
		status: Type.Optional(StringEnum(SEMANTIC_EVENT_STATUSES)),
		because: compactStringArray("Concise reasons supporting this checkpoint"),
		evidence: compactStringArray("Observable evidence or references"),
		supersedes: compactStringArray("Earlier semantic event IDs replaced by this event"),
		relatedFiles: compactStringArray("Files relevant to this checkpoint"),
		relatedSymbols: compactStringArray("Symbols relevant to this checkpoint"),
	},
	{ additionalProperties: false },
);

export type SemanticEventInput = Static<typeof SemanticEventInputSchema>;

interface LedgerEventBase {
	id: string;
	timestamp: string;
	summary: string;
}

export interface SemanticLedgerEvent extends LedgerEventBase {
	family: "semantic";
	type: SemanticEventType;
	status?: SemanticEventStatus;
	because?: string[];
	evidence?: string[];
	supersedes?: string[];
	relatedFiles?: string[];
	relatedSymbols?: string[];
}

export interface ExecutionLedgerEvent extends LedgerEventBase {
	family: "execution";
	type: ExecutionEventType;
	data?: ExecutionEventData;
}

export type LedgerEvent = SemanticLedgerEvent | ExecutionLedgerEvent;

export interface EventFactoryOptions {
	createId?: () => string;
	now?: () => Date;
}

function normalizeText(value: string, field: string): string {
	const normalized = value.replace(/\s+/g, " ").trim();
	if (normalized.length === 0) throw new Error(`${field} must not be blank`);
	return normalized;
}

function normalizeList(values: string[] | undefined, field: string): string[] | undefined {
	if (!values) return undefined;
	const normalized = [...new Set(values.map((value) => normalizeText(value, field)))];
	return normalized.length > 0 ? normalized : undefined;
}

function eventIdentity(
	prefix: "sem" | "exec",
	options: EventFactoryOptions,
): Pick<LedgerEventBase, "id" | "timestamp"> {
	return {
		id: `${prefix}-${options.createId?.() ?? randomUUID()}`,
		timestamp: (options.now?.() ?? new Date()).toISOString(),
	};
}

export function createSemanticEvent(input: SemanticEventInput, options: EventFactoryOptions = {}): SemanticLedgerEvent {
	return {
		...eventIdentity("sem", options),
		family: "semantic",
		type: input.type,
		summary: normalizeText(input.summary, "summary"),
		status: input.status,
		because: normalizeList(input.because, "because"),
		evidence: normalizeList(input.evidence, "evidence"),
		supersedes: normalizeList(input.supersedes, "supersedes"),
		relatedFiles: normalizeList(input.relatedFiles, "relatedFiles"),
		relatedSymbols: normalizeList(input.relatedSymbols, "relatedSymbols"),
	};
}

export function createExecutionEvent(
	type: ExecutionEventType,
	summary: string,
	data?: ExecutionEventData,
	options: EventFactoryOptions = {},
): ExecutionLedgerEvent {
	return {
		...eventIdentity("exec", options),
		family: "execution",
		type,
		summary: normalizeText(summary, "summary"),
		data,
	};
}

export function isLedgerEvent(value: unknown): value is LedgerEvent {
	if (!value || typeof value !== "object") return false;
	const candidate = value as Record<string, unknown>;
	return (
		typeof candidate.id === "string" &&
		typeof candidate.timestamp === "string" &&
		typeof candidate.summary === "string" &&
		(candidate.family === "semantic" || candidate.family === "execution") &&
		typeof candidate.type === "string"
	);
}
