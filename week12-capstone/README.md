# 🎓 Capstone project

As the final project of the FrauenLoop "Cloud Engineering Intermediate" cycle, I had to design and deploy the foundational Azure infrastructure for a secure Web-Application using Terraform.

The main problem is around making the web app and backend access secure.
This is the high-level diagram:

![High level diagram](https://github.com/Dominikasc/frauenloop_dominika/blob/main/week12-capstone/azure-architecture-example.drawio.png)

## Module descriptions

### Providers, Variables & Outputs
Defines the Azure provider and authentication context. Contains all variables and outputs used across the project for configuration and reuse.

### Networking
Creates the virtual network infrastructure, including public and private subnets, NSGs, and VM connectivity. Enables VNet integration for the App Service and secures frontend/backend communication.

### Compute
Deploys the App Service Plan and a Linux-based web application as the frontend. Adds monitoring for App Service, VM, and storage to enable diagnostics and visibility.

### Storage
Provisions a storage account, container, and blob. Sets up a Key Vault for storing secrets and API keys, with access granted to the web app’s managed identity.

### Lessons
- Start out with the diagram for better understanding of what to implement
- Implement one by one and deploy to terraform to simplify debugging