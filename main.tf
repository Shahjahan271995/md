resource "azurerm_resource_group" "bastion-rg" {

  name     = "bastionrg"
  location = "south india"
}
resource "azurerm_key_vault" "keyvault" {
    depends_on = [ azurerm_resource_group.bastion-rg]
  name                        = "bastionkey"
  location                    = "south india"
  resource_group_name         = "bastionrg"
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id


    secret_permissions = ["Get","List","Set","Recover","Delete","Restore","Purge","Backup"]

    
  }
}
resource "azurerm_key_vault_secret" "username" {
  name         = "Bastion-username"
  value        = "Shah"
  key_vault_id = azurerm_key_vault.keyvault.id
}
resource "azurerm_key_vault_secret" "Password" {
  name         = "md-Password"
  value        = "Shah@1"
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_virtual_network" "bastion-vnet" {
  depends_on          = [azurerm_resource_group.bastion-rg]
  name                = "bastionvnet"
  location            = "south india"
  resource_group_name = "bastionrg"
  address_space       = ["10.0.0.0/16"]

}
resource "azurerm_subnet" "vm-subnet" {
  depends_on           = [azurerm_virtual_network.bastion-vnet]
  name                 = "vmsubnet"
  resource_group_name  = "bastionrg"
  virtual_network_name = "bastionvnet"
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_subnet" "bastion-subnet" {
  depends_on           = [azurerm_virtual_network.bastion-vnet]
  name                 = "AzureBastionSubnet"
  resource_group_name  = "bastionrg"
  virtual_network_name = "bastionvnet"
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "bastion-pip" {
  depends_on          = [azurerm_subnet.vm-subnet]
  name                = "bastionpublicip"
  location            = "south india"
  resource_group_name = "bastionrg"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "mdbastion"
  location            = "south india"
  resource_group_name = "bastionrg"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion-subnet.id
    public_ip_address_id = azurerm_public_ip.bastion-pip.id
  }
}

resource "azurerm_network_interface" "nic" {
  depends_on          = [azurerm_subnet.vm-subnet]
  name                = "Bastion-nic"
  location            = "South india"
  resource_group_name = "bastionrg"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  depends_on                      = [azurerm_network_interface.nic]
  name                            = "Bastion-machine"
  resource_group_name             = "bastionrg"
  location                        = "south india"
  size                            = "Standard_F2"
  admin_username                  = "adminuser"
  admin_password                  = "adminuser@123"
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}