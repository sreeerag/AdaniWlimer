data "azurerm_virtual_machine" "example" {
  name                = var.vm_name
  resource_group_name = var.rgname# where your VM resides in your subscription
}

output "virtual_machine_id" {
  value = data.azurerm_virtual_machine.example.id
}

resource "azurerm_storage_account" "main" {
  name                     = var.storage1
  resource_group_name      = data.azurerm_virtual_machine.example.resource_group_name # where your VM resides in your subscription
  location                 = data.azurerm_virtual_machine.example.location # which region your VM resides 
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_log_analytics_workspace" "LAW" {
  name                = var.law
 location            = data.azurerm_virtual_machine.example.location #which region your VM resides 
  resource_group_name = data.azurerm_virtual_machine.example.resource_group_name # where your VM resides in your subscription
}

resource "azurerm_log_analytics_solution" "example" {
  solution_name         = "SecurityCenterFree"
  location              = data.azurerm_virtual_machine.example.location # which region your VM resides 
  resource_group_name   = data.azurerm_virtual_machine.example.resource_group_name # where your VM resides in your subscription
  workspace_resource_id = azurerm_log_analytics_workspace.LAW.id
  workspace_name        = azurerm_log_analytics_workspace.LAW.name
  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityCenterFree"
  }
}
resource "azurerm_monitor_data_collection_rule" "mdcr" {
  name                = "DCAWLSAPDCR"
  resource_group_name = data.azurerm_virtual_machine.example.resource_group_name
  location            = data.azurerm_virtual_machine.example.location
  destinations {
    azure_monitor_metrics {
      name = "Azure-Monitor-Logs"
    }
  }
  data_flow {
    streams      = ["Microsoft-InsightsMetrics"]
    destinations = ["Azure-Monitor-Logs"]
  }
}

#resource "azurerm_monitor_data_collection_endpoint" "dce1" {
#  name                = "DCAWLSAPdce"
#  resource_group_name = data.azurerm_virtual_machine.example.resource_group_name
 # location            = data.azurerm_virtual_machine.example.location
#}

# associate to a Data Collection Rule
resource "azurerm_monitor_data_collection_rule_association" "dcra" {
  name                    = "DCAWLSAPdcra"
  target_resource_id      = data.azurerm_virtual_machine.example.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.mdcr.id
}

# associate to a Data Collection Endpoint
#resource "azurerm_monitor_data_collection_rule_association" "dcea" {
#  target_resource_id          = data.azurerm_virtual_machine.example.id
#  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce1.id
#}
# Agent for Linux
resource "azurerm_virtual_machine_extension" "OMS" {
  name                       = "OMSExtension"
  virtual_machine_id         =  data.azurerm_virtual_machine.example.id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "OmsAgentForLinux"
  type_handler_version       = "1.13"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "workspaceId" : "${azurerm_log_analytics_workspace.LAW.workspace_id}"
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "workspaceKey" : "${azurerm_log_analytics_workspace.LAW.primary_shared_key}"
    }
  PROTECTED_SETTINGS
}

# Dependency Agent for Linux
resource "azurerm_virtual_machine_extension" "da" {
  name                       = "DepedencyAgent"
  virtual_machine_id         =  data.azurerm_virtual_machine.example.id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentLinux"
  type_handler_version       = "9.5"
  auto_upgrade_minor_version = true

}
#Agent for Windows
#resource "azurerm_virtual_machine_extension" "MMA" {
#  name                       = "test-MMAextension"
#  virtual_machine_id         =  data.azurerm_virtual_machine.example.id
#  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
#  type                       = "MicrosoftMonitoringAgent"
#  type_handler_version       = "1.0"
#  auto_upgrade_minor_version = true

#  settings = <<SETTINGS
#    {
#      "workspaceId" : "${azurerm_log_analytics_workspace.LAW.workspace_id}"
#    }
#  SETTINGS

#  protected_settings = <<PROTECTED_SETTINGS
#    {
#      "workspaceKey" : "${azurerm_log_analytics_workspace.LAW.primary_shared_key}"
#    }
#  PROTECTED_SETTINGS
#}

# Dependency Agent for Windows
#resource "azurerm_virtual_machine_extension" "da2" {
#  name                       = "DAExtension"
#  virtual_machine_id         =  data.azurerm_virtual_machine.example.id
#  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
#  type                       = "DependencyAgentWindows"
#  type_handler_version       = "9.5"
#  auto_upgrade_minor_version = true

#}