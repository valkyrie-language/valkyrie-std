# Atlas.Cloud Wire 注册 — 独立于 atlas 内核的云端口状态

namespace atlas.cloud;

using std.text;
using atlas.wire;

class AtlasCloudWireState {
    blob_kind: utf8
    sms_kind: utf8
    email_kind: utf8
    key_vault_kind: utf8
    chat_kind: utf8
    embedding_kind: utf8
    image_kind: utf8
    speech_kind: utf8
    translation_kind: utf8
    search_kind: utf8
    push_kind: utf8
    cdn_kind: utf8
    null_blob: NullBlobStorage
    null_sms: NullSmsProvider
    null_email: NullEmailSender
    null_key_vault: NullKeyVaultService
    null_chat: NullChatCompletionService
    null_embedding: NullEmbeddingService
    null_image: NullImageGenerationService
    null_speech: NullSpeechService
    null_translation: NullTranslationService
    null_search: NullSearchService
    null_push: NullPushNotificationService
    null_cdn: NullCdnService
}

imply AtlasCloudWireState {
    micro new(): Self {
        return Self {
            blob_kind: "null",
            sms_kind: "null",
            email_kind: "null",
            key_vault_kind: "null",
            chat_kind: "null",
            embedding_kind: "null",
            image_kind: "null",
            speech_kind: "null",
            translation_kind: "null",
            search_kind: "null",
            push_kind: "null",
            cdn_kind: "null",
            null_blob: NullBlobStorage::new(),
            null_sms: NullSmsProvider::new(),
            null_email: NullEmailSender::new(),
            null_key_vault: NullKeyVaultService::new(),
            null_chat: NullChatCompletionService::new(),
            null_embedding: NullEmbeddingService::new(),
            null_image: NullImageGenerationService::new(),
            null_speech: NullSpeechService::new(),
            null_translation: NullTranslationService::new(),
            null_search: NullSearchService::new(),
            null_push: NullPushNotificationService::new(),
            null_cdn: NullCdnService::new()
        }
    }

    micro use_blob_kind(mut self, kind: utf8): Self {
        self.blob_kind = kind
        return self
    }

    micro use_sms_kind(mut self, kind: utf8): Self {
        self.sms_kind = kind
        return self
    }

    micro use_email_kind(mut self, kind: utf8): Self {
        self.email_kind = kind
        return self
    }
}

micro require_blob(state: AtlasCloudWireState): NullBlobStorage {
    return state.null_blob
}

micro require_sms(state: AtlasCloudWireState): NullSmsProvider {
    return state.null_sms
}

micro require_email(state: AtlasCloudWireState): NullEmailSender {
    return state.null_email
}

micro require_key_vault(state: AtlasCloudWireState): NullKeyVaultService {
    return state.null_key_vault
}

micro require_chat(state: AtlasCloudWireState): NullChatCompletionService {
    return state.null_chat
}

micro require_embedding(state: AtlasCloudWireState): NullEmbeddingService {
    return state.null_embedding
}

micro require_image(state: AtlasCloudWireState): NullImageGenerationService {
    return state.null_image
}

micro require_speech(state: AtlasCloudWireState): NullSpeechService {
    return state.null_speech
}

micro require_translation(state: AtlasCloudWireState): NullTranslationService {
    return state.null_translation
}

micro require_search(state: AtlasCloudWireState): NullSearchService {
    return state.null_search
}

micro require_push(state: AtlasCloudWireState): NullPushNotificationService {
    return state.null_push
}

micro require_cdn(state: AtlasCloudWireState): NullCdnService {
    return state.null_cdn
}

micro link_cloud_to_container(container: AtlasWireContainer, state: AtlasCloudWireState): AtlasWireContainer {
    container.register_key("AtlasCloudWireState")
    let _state: AtlasCloudWireState = state
    return container
}

micro cloud_wire_from_container(container: AtlasWireContainer): AtlasCloudWireState {
    let _c: AtlasWireContainer = container
    return AtlasCloudWireState::new()
}
