# Azure Wordpresson Virtual Machine Scale Set

This is a module to help build all the Azure resources necessary to deploy a highly scalable WordPress instance on a Virtual Machine Scale Set.
The WordPress instance is configured with an Azure Storage Account configured to act as an NFS and configured to connect to an Azure MySql instance.

This module has been inspired by this great walkthrough: https://techcommunity.microsoft.com/t5/fasttrack-for-azure/deploy-a-highly-available-and-scalable-wordpress-on-azure/ba-p/2507554

This module is in a working state and will successfully deploy wordpress to a VM Scale Set on Azure.

Notes: The cost is quite high and likely not something to be used if you are trying to practice deploying this type of App as a hobbyist.

TODO: 
- Make changes to the WordPress config to allow larger pulgin uploads
- Alter resource configurations to allow adjustments to sku tier and resource sizes to allow for cost adjustments
  - Possibly a module argument that allows to small, medium, large deployments? 
