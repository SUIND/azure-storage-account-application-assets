resource "azurerm_resource_group" "main" {
  name     = var.md_metadata.name_prefix
  location = var.account.region
  tags     = var.md_metadata.default_tags
}

module "azure_storage_account" {
  source              = "github.com/SUIND/terraform-modules//azure/storage-account?ref=0ff9180"
  name                = var.md_metadata.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  kind                = "StorageV2"
  tier                = "Standard"
  access_tier         = "Hot"
  replication_type    = var.redundancy.replication_type
  tags                = var.md_metadata.default_tags

  blob_properties = {
    delete_retention_policy           = var.redundancy.data_protection
    container_delete_retention_policy = var.redundancy.data_protection
  }
}

resource "azurerm_servicebus_namespace" "main" {
  name                = var.md_metadata.name_prefix
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Basic"
}

resource "azurerm_servicebus_queue" "main" {
  name                = var.md_metadata.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  namespace_name      = azurerm_servicebus_namespace.main.name
  enable_partitioning = false
}

resource "azurerm_eventgrid_system_topic" "main" {
  name                   = var.md_metadata.name_prefix
  location               = azurerm_resource_group.main.location 
  resource_group_name    = azurerm_resource_group.main.name 
  source_arm_resource_id = module.azure_storage_account.account_id
  topic_type             = "Microsoft.Storage.StorageAccounts"
}

resource "azurerm_eventgrid_system_topic_event_subscription" "main" {
  name                = var.md_metadata.name_prefix
  system_topic        = azurerm_eventgrid_system_topic.main.name
  resource_group_name = azurerm_resource_group.main.name

  included_event_types = [
    "Microsoft.Storage.BlobCreated"
  ]

  service_bus_queue_id = azurerm_servicebus_queue.main.id
}

resource "azurerm_servicebus_namespace_authorization_rule" "main" {
  name                = var.md_metadata.name_prefix
  namespace_name      = azurerm_servicebus_namespace.main.name
  resource_group_name = azurerm_resource_group.main.name

  listen = true
  send   = false
  manage = false
}