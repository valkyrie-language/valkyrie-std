# Atlas.Cloud 共享 DTO（对标 C# Atlas.Cloud.Models）

namespace atlas.cloud;

using std.text;

struct BlobResult {
    success: bool
    error: utf8
    etag: utf8
}

struct BlobInfo {
    key: utf8
    size: i64
    etag: utf8
}

struct SmsResult {
    success: bool
    error: utf8
    request_id: utf8
}

struct ChatMessage {
    role: utf8
    content: utf8
}

struct ChatRequest {
    model: utf8
    temperature: f64
    max_tokens: i32
}

struct ChatResponse {
    id: utf8
    model: utf8
    message: ChatMessage
    finish_reason: utf8
    usage_total_tokens: i32
}

struct EmbeddingRequest {
    model: utf8
    input: utf8
}

struct EmbeddingResponse {
    model: utf8
    dimensions: i32
}

struct ImageGenerationRequest {
    model: utf8
    prompt: utf8
    size: utf8
}

struct ImageGenerationResponse {
    url: utf8
    revised_prompt: utf8
}

struct TtsRequest {
    text: utf8
    voice: utf8
    format: utf8
}

struct SpeechRecognitionResult {
    text: utf8
    confidence: f64
}

struct TranslationRequest {
    text: utf8
    source_lang: utf8
    target_lang: utf8
}

struct TranslationResult {
    text: utf8
    source_lang: utf8
    target_lang: utf8
}

struct SearchRequest {
    index: utf8
    query: utf8
    limit: i32
}

struct SearchHit {
    id: utf8
    score: f64
    snippet: utf8
}

struct SearchResult {
    total: i32
    took_ms: i32
}

struct PushRequest {
    title: utf8
    body: utf8
    token: utf8
    platform: utf8
}

struct PushResult {
    success: bool
    error: utf8
    message_id: utf8
}

struct CdnResult {
    success: bool
    error: utf8
    task_id: utf8
}

imply BlobResult {
    micro ok(etag: utf8): Self {
        return Self { success: true, error: "", etag: etag }
    }

    micro fail(error: utf8): Self {
        return Self { success: false, error: error, etag: "" }
    }
}

imply SmsResult {
    micro ok(request_id: utf8): Self {
        return Self { success: true, error: "", request_id: request_id }
    }

    micro fail(error: utf8): Self {
        return Self { success: false, error: error, request_id: "" }
    }
}

imply ChatMessage {
    micro new(role: utf8, content: utf8): Self {
        return Self { role: role, content: content }
    }
}

imply ChatRequest {
    micro new(model: utf8): Self {
        return Self { model: model, temperature: 0.7, max_tokens: 1024 }
    }
}

imply ChatResponse {
    micro empty(): Self {
        return Self {
            id: "",
            model: "",
            message: ChatMessage::new("", ""),
            finish_reason: "",
            usage_total_tokens: 0
        }
    }
}

imply PushResult {
    micro ok(message_id: utf8): Self {
        return Self { success: true, error: "", message_id: message_id }
    }

    micro fail(error: utf8): Self {
        return Self { success: false, error: error, message_id: "" }
    }
}

imply CdnResult {
    micro ok(task_id: utf8): Self {
        return Self { success: true, error: "", task_id: task_id }
    }

    micro fail(error: utf8): Self {
        return Self { success: false, error: error, task_id: "" }
    }
}
