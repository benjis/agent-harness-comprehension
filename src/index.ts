import { CONFIG_DIR_NAME, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { createComprehensionExtension } from "./extension.ts";

export default function comprehensionExtension(pi: ExtensionAPI) {
	createComprehensionExtension(pi, CONFIG_DIR_NAME);
}
