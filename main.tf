terraform {
  required_providers {
    azurerm = ">= 2.10.0"
  }
}

provider "azurerm" {
    features {}
}

locals {
    mycommand1 = "Install-WindowsFeature Telnet-Client"
    mycommand2 = "Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature"
    mycommand  = "${local.mycommand1}; ${local.mycommand2}"
    myad1      = "Import-Module ADDSDeployment"
    myad2      = "$password = ConvertTo-SecureString ${var.admin_pass} -AsPlainText -Force"
    myad3      = "Add-WindowsFeature -name ad-domain-services -IncludeManagementTools"
    myad4      = "Install-ADDSForest -CreateDnsDelegation:$false -DomainMode Win2012R2 -DomainName ${var.addomain} -DomainNetbiosName ${var.nbname} -ForestMode Win2012R2 -InstallDns:$true -SafeModeAdministratorPassword $password -Force:$true"
    myad5      = "shutdown -r -t 10"
    myad6      = "exit 0"
    myad       = "${local.myad1}; ${local.myad2}; ${local.myad3}; ${local.myad4}; ${local.myad5}; ${local.myad6}"
}

resource "azurerm_resource_group" "rg1" {
  name     = "${var.companypf}-rg"
  location = var.region
}

resource "azurerm_virtual_network" "vn1" {
  name                = "${var.companypf}-vnet"
  address_space       = var.vnet
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
}

resource "azurerm_subnet" "sub1" {
  name                 = "${var.companypf}-sub1"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vn1.name
  address_prefixes     = var.serversub
}

resource "azurerm_public_ip" "nicpub" {
    name = "${var.companypf}-pubip"
    location = azurerm_resource_group.rg1.location
    resource_group_name = azurerm_resource_group.rg1.name
    allocation_method = "Dynamic"
}

resource "azurerm_network_interface" "int1" {
  name                = "${var.companypf}-nic1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  ip_configuration {
    name                          = "nic1"
    subnet_id                     = azurerm_subnet.sub1.id
#    private_ip_address_allocation = "Dynamic"
    private_ip_address_allocation = "static"
    private_ip_address = var.pdc1_ip
    public_ip_address_id = azurerm_public_ip.nicpub.id
  }
  dns_servers = var.dns
  
}

#resource "azurerm_windows_virtual_machine" "vm1" {
#  name                = "${var.companypf}-DC01"
#  resource_group_name = azurerm_resource_group.rg1.name
#  location            = azurerm_resource_group.rg1.location
#  size                = "Standard_F2"
#  admin_username      = var.admin_user
#  admin_password      = var.admin_pass
#  network_interface_ids = [
#    azurerm_network_interface.int1.id,
#  ]
#    tags = {
#    environment = "prod"
#  }

#  os_disk {
#    caching              = "ReadWrite"
#    storage_account_type = "Standard_LRS"
#  }
#
#  source_image_reference {
#    publisher = "MicrosoftWindowsServer"
#    offer     = "WindowsServer"
#    sku       = "2016-Datacenter"
#    version   = "latest"
#  }
# }

# resource "azurerm_virtual_machine_extension" "AD" {
#    name                    = "AD"
#    virtual_machine_id      = azurerm_windows_virtual_machine.vm1.id
#    publisher               = "Microsoft.Compute"
#    type                    = "CustomScriptExtension"
#    type_handler_version    = "1.10"
#    
#    settings = <<SETTINGS
#    {
#        "commandToExecute": "powershell.exe -Command \"${local.myad}\""
#    }
#    SETTINGS
#}