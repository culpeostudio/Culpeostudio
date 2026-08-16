package providerconn

// RetiredPresetIDs are vendors that were once connectable here and are now
// built-in Marketplace sources instead: they ship with the app, hold their key
// in the app settings, and their models are added through the Marketplace
// rather than activated from a connection catalogue.  Connections left over
// from the old flow are dropped on load so those models leave the model list.
var RetiredPresetIDs = map[string]struct{}{
	"openrouter":  {},
	"featherless": {},
}

// Presets is intentionally a curated, documented list rather than a claim to
// enumerate every AI company.  The custom OpenAI-compatible option keeps the
// integration open-ended while these entries receive first-class defaults and
// safer endpoint validation.
//
// Marketplace-backed vendors (see RetiredPresetIDs) deliberately have no entry:
// they are always present in the Anbieter panel and only need a key.
var presets = []Preset{
	{
		ID:               "openai",
		Name:             "OpenAI API (GPT)",
		Description:      "GPT-Modelle über dein separates OpenAI-API-Konto. Ein ChatGPT-Abo enthält kein API-Guthaben.",
		Protocol:         ProtocolOpenAICompatible,
		DefaultBaseURL:   "https://api.openai.com/v1",
		DocumentationURL: "https://developers.openai.com/api/reference/resources/models/methods/list",
		APIKeyRequired:   true,
		Available:        true,
	},
	{
		ID:               "anthropic",
		Name:             "Anthropic (Claude)",
		Description:      "Claude über die native Messages API inklusive Streaming.",
		Protocol:         ProtocolAnthropic,
		DefaultBaseURL:   "https://api.anthropic.com",
		DocumentationURL: "https://platform.claude.com/docs/en/api/models/list",
		APIKeyRequired:   true,
		Available:        true,
	},
	{
		ID:               "google_gemini",
		Name:             "Google Gemini API",
		Description:      "Gemini über die native Google GenAI API inklusive Modell-Metadaten und Streaming.",
		Protocol:         ProtocolGoogleGenAI,
		DefaultBaseURL:   "https://generativelanguage.googleapis.com",
		DocumentationURL: "https://ai.google.dev/api/models",
		APIKeyRequired:   true,
		Available:        true,
	},
	{
		ID:               "qwen_model_studio",
		Name:             "Qwen / Alibaba Model Studio",
		Description:      "Qwen und freigegebene Drittmodelle über den Pay-as-you-go OpenAI-kompatiblen Endpunkt.",
		Protocol:         ProtocolOpenAICompatible,
		DefaultBaseURL:   "https://dashscope.aliyuncs.com/compatible-mode/v1",
		DocumentationURL: "https://www.alibabacloud.com/help/en/model-studio/base-url",
		APIKeyRequired:   true,
		Available:        true,
	},
	{
		ID:               "qwen_coding_plan",
		Name:             "Qwen Coding Plan",
		Description:      "Dein eigener Qwen-Coding-Plan-Zugang über deinen eigenen Alibaba-Account und API-Schlüssel. Culpeo Studio stellt selbst keinen Zugang bereit oder verkauft ihn weiter.",
		Protocol:         ProtocolOpenAICompatible,
		DefaultBaseURL:   "https://coding-intl.dashscope.aliyuncs.com/v1",
		DocumentationURL: "https://www.alibabacloud.com/help/en/model-studio/coding-plan",
		APIKeyRequired:   true,
		Available:        true,
	},
	{
		ID:               "mistral",
		Name:             "Mistral AI",
		Description:      "Mistral-Modelle über die OpenAI-kompatible Chat-Schnittstelle.",
		Protocol:         ProtocolOpenAICompatible,
		DefaultBaseURL:   "https://api.mistral.ai/v1",
		DocumentationURL: "https://docs.mistral.ai/api/endpoint/models",
		APIKeyRequired:   true,
		Available:        true,
	},
	{
		ID:               "groq",
		Name:             "GroqCloud",
		Description:      "Schnelle Inferenz für offene Modelle über eine OpenAI-kompatible API.",
		Protocol:         ProtocolOpenAICompatible,
		DefaultBaseURL:   "https://api.groq.com/openai/v1",
		DocumentationURL: "https://console.groq.com/docs/models",
		APIKeyRequired:   true,
		Available:        true,
	},
	{
		ID:               "together",
		Name:             "Together AI",
		Description:      "Offene und proprietäre Modelle über Together's OpenAI-kompatible Inferenz-API.",
		Protocol:         ProtocolOpenAICompatible,
		DefaultBaseURL:   "https://api.together.xyz/v1",
		DocumentationURL: "https://docs.together.ai/docs/inference/openai-compatibility",
		APIKeyRequired:   true,
		Available:        true,
	},
	{
		ID:               "deepseek",
		Name:             "DeepSeek",
		Description:      "DeepSeek-Modelle über die OpenAI-kompatible API.",
		Protocol:         ProtocolOpenAICompatible,
		DefaultBaseURL:   "https://api.deepseek.com",
		DocumentationURL: "https://api-docs.deepseek.com/api/list-models",
		APIKeyRequired:   true,
		Available:        true,
	},
	{
		ID:               "perplexity",
		Name:             "Perplexity",
		Description:      "Perplexity-Modelle und Sonar-Suche über die dokumentierte OpenAI-kompatible API.",
		Protocol:         ProtocolOpenAICompatible,
		DefaultBaseURL:   "https://api.perplexity.ai/v1",
		DocumentationURL: "https://docs.perplexity.ai/api-reference/models-get",
		APIKeyRequired:   true,
		Available:        true,
	},
	{
		ID:               "fireworks",
		Name:             "Fireworks AI",
		Description:      "Account-spezifischer Modellkatalog mit OpenAI-kompatibler Inferenz.",
		Protocol:         ProtocolOpenAICompatible,
		DefaultBaseURL:   "https://api.fireworks.ai/inference/v1",
		DocumentationURL: "https://docs.fireworks.ai/tools-sdks/openai-compatibility",
		APIKeyRequired:   true,
		Available:        true,
	},
	{
		ID:   "aws_bedrock",
		Name: "AWS Bedrock",
		Description: "Amazon Bedrock über dessen OpenAI-kompatiblen Endpunkt, z. B. " +
			"https://bedrock-runtime.DEINE-REGION.amazonaws.com/openai/v1. Erfordert einen Bedrock-API-Schlüssel.",
		Protocol:         ProtocolOpenAICompatible,
		DefaultBaseURL:   "",
		DocumentationURL: "https://docs.aws.amazon.com/bedrock/latest/userguide/inference-invoke-model-openai.html",
		APIKeyRequired:   true,
		Available:        true,
	},
	{
		ID:   "azure_openai",
		Name: "Azure OpenAI",
		Description: "Deine eigene Azure-OpenAI-Bereitstellung, z. B. " +
			"https://DEINE-RESSOURCE.openai.azure.com/openai/deployments/DEIN-DEPLOYMENT. Erfordert eine Azure-OpenAI-Ressource.",
		Protocol:         ProtocolOpenAICompatible,
		DefaultBaseURL:   "",
		DocumentationURL: "https://learn.microsoft.com/en-us/azure/ai-services/openai/reference",
		APIKeyRequired:   true,
		Available:        true,
	},
	{
		ID:               CustomPresetID,
		Name:             "Eigener OpenAI-kompatibler Anbieter",
		Description:      "Für weitere API-Anbieter oder einen eigenen HTTPS-Endpunkt, der /models und /chat/completions unterstützt.",
		Protocol:         ProtocolOpenAICompatible,
		DefaultBaseURL:   "",
		DocumentationURL: "",
		APIKeyRequired:   false,
		Available:        true,
	},
}

func Presets() []Preset {
	// Keep a deterministic, intentionally curated display order.
	return append([]Preset(nil), presets...)
}

func FindPreset(id string) (Preset, bool) {
	for _, preset := range presets {
		if preset.ID == id {
			return preset, true
		}
	}
	return Preset{}, false
}
