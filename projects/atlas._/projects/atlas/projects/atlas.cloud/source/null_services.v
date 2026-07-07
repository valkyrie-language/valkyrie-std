# Atlas.Cloud Null 实现 — 未配置云服务时的安全降级

namespace atlas.cloud;

using std.text;

class NullBlobStorage {
    _pad: i32
}

imply NullBlobStorage {
    micro new(): Self {
        return Self { _pad: 0 }
    }

    micro put_object(self, bucket: utf8, key: utf8, data: utf8, content_type: utf8): BlobResult {
        let _b: utf8 = bucket
        let _k: utf8 = key
        let _d: utf8 = data
        let _c: utf8 = content_type
        return BlobResult::fail("blob storage not configured")
    }

    micro get_object(self, bucket: utf8, key: utf8): utf8 {
        let _b: utf8 = bucket
        let _k: utf8 = key
        return ""
    }

    micro delete_object(self, bucket: utf8, key: utf8): BlobResult {
        let _b: utf8 = bucket
        let _k: utf8 = key
        return BlobResult::fail("blob storage not configured")
    }

    micro generate_presigned_url(self, bucket: utf8, key: utf8, expiry_seconds: i32, method: utf8): utf8 {
        let _b: utf8 = bucket
        let _k: utf8 = key
        let _e: i32 = expiry_seconds
        let _m: utf8 = method
        return ""
    }
}

class NullEmailSender {
    _pad: i32
}

imply NullEmailSender {
    micro new(): Self {
        return Self { _pad: 0 }
    }

    micro send(self, to: utf8, subject: utf8, body: utf8): unit {
        let _t: utf8 = to
        let _s: utf8 = subject
        let _b: utf8 = body
    }
}

class NullSmsProvider {
    _pad: i32
}

imply NullSmsProvider {
    micro new(): Self {
        return Self { _pad: 0 }
    }

    micro send(self, phone: utf8, template_code: utf8, sign_name: utf8): SmsResult {
        let _p: utf8 = phone
        let _t: utf8 = template_code
        let _s: utf8 = sign_name
        return SmsResult::fail("sms provider not configured")
    }
}

class NullKeyVaultService {
    _pad: i32
}

imply NullKeyVaultService {
    micro new(): Self {
        return Self { _pad: 0 }
    }

    micro get_secret(self, key_name: utf8): utf8 {
        let _k: utf8 = key_name
        return ""
    }

    micro set_secret(self, key_name: utf8, value: utf8): unit {
        let _k: utf8 = key_name
        let _v: utf8 = value
    }

    micro delete_secret(self, key_name: utf8): unit {
        let _k: utf8 = key_name
    }
}

class NullChatCompletionService {
    _pad: i32
}

imply NullChatCompletionService {
    micro new(): Self {
        return Self { _pad: 0 }
    }

    micro complete(self, request: ChatRequest): ChatResponse {
        let _r: ChatRequest = request
        return ChatResponse::empty()
    }
}

class NullEmbeddingService {
    _pad: i32
}

imply NullEmbeddingService {
    micro new(): Self {
        return Self { _pad: 0 }
    }

    micro embed(self, request: EmbeddingRequest): EmbeddingResponse {
        let _r: EmbeddingRequest = request
        return EmbeddingResponse { model: "", dimensions: 0 }
    }
}

class NullImageGenerationService {
    _pad: i32
}

imply NullImageGenerationService {
    micro new(): Self {
        return Self { _pad: 0 }
    }

    micro generate(self, request: ImageGenerationRequest): ImageGenerationResponse {
        let _r: ImageGenerationRequest = request
        return ImageGenerationResponse { url: "", revised_prompt: "" }
    }
}

class NullSpeechService {
    _pad: i32
}

imply NullSpeechService {
    micro new(): Self {
        return Self { _pad: 0 }
    }

    micro tts(self, request: TtsRequest): utf8 {
        let _r: TtsRequest = request
        return ""
    }

    micro asr(self, audio: utf8, format: utf8): SpeechRecognitionResult {
        let _a: utf8 = audio
        let _f: utf8 = format
        return SpeechRecognitionResult { text: "", confidence: 0.0 }
    }
}

class NullTranslationService {
    _pad: i32
}

imply NullTranslationService {
    micro new(): Self {
        return Self { _pad: 0 }
    }

    micro translate(self, request: TranslationRequest): TranslationResult {
        let _r: TranslationRequest = request
        return TranslationResult { text: "", source_lang: "", target_lang: "" }
    }
}

class NullSearchService {
    _pad: i32
}

imply NullSearchService {
    micro new(): Self {
        return Self { _pad: 0 }
    }

    micro search(self, request: SearchRequest): SearchResult {
        let _r: SearchRequest = request
        return SearchResult { total: 0, took_ms: 0 }
    }

    micro index(self, index_name: utf8, document_id: utf8, document: utf8): unit {
        let _i: utf8 = index_name
        let _d: utf8 = document_id
        let _doc: utf8 = document
    }

    micro delete_index(self, index_name: utf8, document_id: utf8): unit {
        let _i: utf8 = index_name
        let _d: utf8 = document_id
    }
}

class NullPushNotificationService {
    _pad: i32
}

imply NullPushNotificationService {
    micro new(): Self {
        return Self { _pad: 0 }
    }

    micro push(self, request: PushRequest): PushResult {
        let _r: PushRequest = request
        return PushResult::fail("push service not configured")
    }
}

class NullCdnService {
    _pad: i32
}

imply NullCdnService {
    micro new(): Self {
        return Self { _pad: 0 }
    }

    micro purge(self, urls: [utf8]): CdnResult {
        let _u: [utf8] = urls
        return CdnResult::fail("cdn service not configured")
    }

    micro prefetch(self, urls: [utf8]): CdnResult {
        let _u: [utf8] = urls
        return CdnResult::fail("cdn service not configured")
    }
}
