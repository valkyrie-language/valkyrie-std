# Azure 云服务注册辅助

namespace atlas.cloud.azure;

using std.text;
using atlas.cloud;

struct AzureCloudOptions {
    connection_string: utf8
    from_address: utf8
    account_name: utf8
    account_key: utf8
}

class AzureCloudBundle {
    state: AtlasCloudWireState
    email: AzureEmailSender
    blob: AzureBlobStorage
}

imply AzureCloudOptions {
    micro new(connection_string: utf8, from_address: utf8, account_name: utf8, account_key: utf8): Self {
        return Self {
            connection_string: connection_string,
            from_address: from_address,
            account_name: account_name,
            account_key: account_key
        }
    }
}

micro register_azure_cloud(mut state: AtlasCloudWireState, opts: AzureCloudOptions): AzureCloudBundle {
    state = state.use_email_kind("azure")
    state = state.use_blob_kind("azure")
    return AzureCloudBundle {
        state: state,
        email: AzureEmailSender::new(opts.connection_string, opts.from_address),
        blob: AzureBlobStorage::new(opts.account_name, opts.account_key)
    }
}
