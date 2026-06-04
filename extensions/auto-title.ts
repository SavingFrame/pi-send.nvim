import { complete } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const CUSTOM_TYPE = "auto-title";
const TITLE_PREFIX = "pi";
const FUNNY_FALLBACK_TITLES = [
	"sleepy raccoon",
	"spicy noodle",
	"confused penguin",
	"tiny wizard",
	"rubber duck council",
	"chaos gardener",
	"cosmic potato",
	"bug whisperer",
	"noisy teapot",
	"feral keyboard",
	"midnight sandwich",
	"dramatic toaster",
	"suspicious banana",
	"moonlit yak",
	"pixel goblin",
];

type AutoTitleEntry = {
	title?: unknown;
};

const isRecord = (value: unknown): value is Record<string, unknown> =>
	typeof value === "object" && value !== null;

const sanitizeTitle = (text: string): string => {
	const title = text
		.replace(/[`'"|:;,.!?()[\]{}<>]/g, " ")
		.replace(/\s+/g, " ")
		.trim()
		.split(" ")
		.filter(Boolean)
		.slice(0, 5)
		.join(" ");

	return title.slice(0, 48).trim();
};

const fallbackTitle = (): string =>
	FUNNY_FALLBACK_TITLES[Math.floor(Math.random() * FUNNY_FALLBACK_TITLES.length)] ?? "tiny wizard";

const formatTerminalTitle = (title: string): string => `${TITLE_PREFIX}|${title}`;

const setTerminalTitle = (title: string, ctx: ExtensionContext): void => {
	const terminalTitle = formatTerminalTitle(title);

	// Pi also sets its own title during session binding. Defer so our routing title wins on startup/resume.
	setTimeout(() => {
		ctx.ui.setTitle(terminalTitle);
	}, 50);
};

const getStoredTitle = (ctx: ExtensionContext): string | null => {
	const entries = ctx.sessionManager.getEntries();

	for (let i = entries.length - 1; i >= 0; i--) {
		const entry = entries[i];
		if (entry.type !== "custom" || entry.customType !== CUSTOM_TYPE || !isRecord(entry.data)) {
			continue;
		}

		const data = entry.data as AutoTitleEntry;
		if (typeof data.title === "string" && data.title.trim()) {
			return sanitizeTitle(data.title);
		}
	}

	return null;
};

const buildTitlePrompt = (firstPrompt: string): string =>
	[
		"Create a short terminal title for this coding-agent session.",
		"Use 2 to 5 plain words.",
		"Return only the title.",
		"Do not use quotes, punctuation, emojis, or prefixes.",
		"",
		"First user message:",
		firstPrompt.slice(0, 4000),
	].join("\n");

const generateTitle = async (firstPrompt: string, ctx: ExtensionContext): Promise<string> => {
	const model = ctx.model;
	if (!model) {
		return sanitizeTitle(fallbackTitle());
	}

	const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
	if (!auth.ok) {
		return sanitizeTitle(fallbackTitle());
	}

	const response = await complete(
		model,
		{
			messages: [
				{
					role: "user" as const,
					content: [{ type: "text" as const, text: buildTitlePrompt(firstPrompt) }],
					timestamp: Date.now(),
				},
			],
		},
		{
			apiKey: auth.apiKey,
			headers: auth.headers,
			maxTokens: 128,
			reasoningEffort: "minimal",
		},
	);

	const text = response.content
		.filter((part): part is { type: "text"; text: string } => part.type === "text")
		.map((part) => part.text)
		.join(" ");

	const title = sanitizeTitle(text);
	return title || sanitizeTitle(fallbackTitle());
};

export default function (pi: ExtensionAPI) {
	let currentTitle: string | null = null;
	let firstPrompt: string | null = null;
	let generating = false;

	pi.on("session_start", async (_event, ctx) => {
		currentTitle = getStoredTitle(ctx);
		firstPrompt = null;
		generating = false;

		if (currentTitle) {
			setTerminalTitle(currentTitle, ctx);
		}
	});

	pi.on("before_agent_start", async (event, ctx) => {
		if (currentTitle || firstPrompt) {
			return;
		}

		const storedTitle = getStoredTitle(ctx);
		if (storedTitle) {
			currentTitle = storedTitle;
			setTerminalTitle(storedTitle, ctx);
			return;
		}

		firstPrompt = event.prompt.trim();
	});

	pi.on("agent_end", async (_event, ctx) => {
		if (currentTitle || !firstPrompt || generating) {
			return;
		}

		generating = true;
		try {
			const title = await generateTitle(firstPrompt, ctx);
			currentTitle = title;
			pi.appendEntry(CUSTOM_TYPE, { title, source: "first-user-message" });
			setTerminalTitle(title, ctx);
		} catch {
			const title = sanitizeTitle(fallbackTitle());
			currentTitle = title;
			pi.appendEntry(CUSTOM_TYPE, { title, source: "fallback" });
			setTerminalTitle(title, ctx);
		} finally {
			generating = false;
		}
	});

	pi.registerCommand("auto-title", {
		description: "Show the auto-generated terminal routing title",
		handler: async (_args, ctx) => {
			const title = currentTitle ?? getStoredTitle(ctx);
			ctx.ui.notify(title ? `Auto title: ${title}` : "No auto title yet", "info");
		},
	});
}
