import { appendFile, mkdir, readFile } from "node:fs/promises";
import { dirname } from "node:path";
import type { LedgerEvent } from "./types.ts";
import { isLedgerEvent } from "./types.ts";

export class ComprehensionLedger {
	readonly path: string;
	lastError: string | undefined;
	private pending: Promise<void> = Promise.resolve();

	constructor(path: string) {
		this.path = path;
	}

	async append(event: LedgerEvent): Promise<boolean> {
		let written = false;
		this.pending = this.pending.then(async () => {
			try {
				await mkdir(dirname(this.path), { recursive: true });
				await appendFile(this.path, `${JSON.stringify(event)}\n`, "utf8");
				this.lastError = undefined;
				written = true;
			} catch (error) {
				this.lastError = error instanceof Error ? error.message : String(error);
			}
		});
		await this.pending;
		return written;
	}

	async readAll(): Promise<LedgerEvent[]> {
		await this.pending;
		try {
			const content = await readFile(this.path, "utf8");
			const events: LedgerEvent[] = [];
			for (const line of content.split("\n")) {
				if (!line.trim()) continue;
				try {
					const parsed: unknown = JSON.parse(line);
					if (isLedgerEvent(parsed)) events.push(parsed);
				} catch {
					// Ignore malformed historical lines; normal writes always append complete JSON records.
				}
			}
			return events;
		} catch (error) {
			const code = error && typeof error === "object" && "code" in error ? error.code : undefined;
			if (code === "ENOENT") return [];
			this.lastError = error instanceof Error ? error.message : String(error);
			return [];
		}
	}
}
