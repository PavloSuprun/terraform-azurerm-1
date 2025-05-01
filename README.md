# Terraform Azure Infrastructure Deployment

This project provisions a full-stack Azure infrastructure using **Terraform**, including compute, networking, database, and DNS resources. It supports application deployment, scaling, and HTTPS traffic encryption using SSL certificate.

---

## Features

This project covers:

- Modularized Terraform setup
- Resource Group creation
- Virtual Network with subnets and NSGs (Custom IP range allowed)
- Ubuntu 22.04 VM and VM Scale Set (VMSS)
- L4 Load Balancer with HTTP (8080) and HTTPS (8443) support
- Azure SQL Server with basic DB, with failover group in another region
- Java app deployment on Tomcat 8 with DB connection
- SSL certificate installation on VM
- Golden image creation for VMSS from a prepared VM
- Domain mapping via DNS Zone

---

## Project Structure

```
variables.tf
providers.tf
main.tf
backend.tf
modules
    ├─── image_gallery 
    │     ├──  main.tf
    │     ├──  outputs.tf
    │     └──  variables.tf
    ├─── key_vault
    │     ├──  main.tf
    │     ├──  outputs.tf
    │     └──  variables.tf
    ├─── network
    │     ├──  main.tf
    │     ├──  outputs.tf
    │     └──  variables.tf
    ├─── resource_group
    │     ├──  main.tf
    │     ├──  outputs.tf
    │     └──  variables.tf
    ├─── sql_server
    │     ├──  main.tf
    │     ├──  outputs.tf
    │     └──  variables.tf
    ├─── vm
    │     ├──  cloud-init.yaml.tpl
    │     ├──  main.tf
    │     ├──  outputs.tf
    │     ├──  tomcat.service
    │     └──  variables.tf
    └─── vmss
          ├──  main.tf
          └──  variables.tf
```

---

## How to Run Locally

### 1. Prerequisites

- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads)
- Azure CLI (`az login` required before Terraform init)
- Git installed

---

### 2. Clone the Repository

```bash
git clone https://github.com/PavloSuprun/terraform-azurerm-1.git
cd terraform-azurerm-1
```

### 3. Create terraform.tfvars
Create a file named **terraform.tfvars** in the root folder and provide values for all variables defined in variables.tf. For example:

```bash
location        = "East US"
sql_admin_user  = "sqladmin"
vm_admin_user   = "azureuser"
vm_admin_ssh_key = "ssh-rsa AAAA..."
allowed_ip_range = "192.168.0.0/16"
```

### 4. Initialize and Apply Terraform

```bash
terraform init
terraform plan
terraform apply
```

## Notes
The VM is configured with Java and Tomcat 8 **[App](https://github.com/PavloSuprun/todo-app)**.
SSL certificate must be generated and uploaded to Azure Key Vault.
Ensure the DNS registrar points the domain to the Load Balancer's public IP by changing domain's Name Servers to Azure DNS ones.

