resource "massdriver_artifact" "azure_storage_account_blob" {
  field                = "azure_storage_account_blob"
  provider_resource_id = module.azure_storage_account.account_id
  name                 = "Azure Blob Storage Account ${var.md_metadata.name_prefix} (${module.azure_storage_account.account_id})"
  artifact = jsonencode(
    {
      data = {
        infrastructure = {
          ari      = module.azure_storage_account.account_id
          endpoint = module.azure_storage_account.primary_blob_endpoint
          connection_str  = module.azure_storage_account.primary_connection_string
          queue_connection_str = azurerm_servicebus_namespace_authorization_rule.main.primary_connection_string
        }
        security = {
          iam = {
            "read" = {
              role  = "Storage Blob Data Reader"
              scope = module.azure_storage_account.account_id
            },
            "read_write" = {
              role  = "Storage Blob Data Contributor"
              scope = module.azure_storage_account.account_id
            }
          }
        }
      }
      specs = {
        azure = {
          region = azurerm_resource_group.main.location
        }
      }
    }
  )
}
