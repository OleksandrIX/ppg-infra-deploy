locals {
  key_vault_policy_bindings = flatten([
    [
      for cluster_key in keys(var.clusters) : {
        cluster_key = cluster_key
        object_id   = data.azurerm_client_config.current.object_id
      }
    ],
    flatten([
      for cluster_key, _ in var.clusters : [
        for object_id in var.additional_key_vault_object_ids : {
          cluster_key = cluster_key
          object_id   = object_id
        }
      ]
    ]),
    [
      for cluster_key, object_id in var.service_connection_object_ids : {
        cluster_key = cluster_key
        object_id   = object_id
      }
      if contains(keys(var.clusters), cluster_key)
    ]
  ])

  key_vault_policies = {
    for policy in local.key_vault_policy_bindings : "${policy.cluster_key}:${policy.object_id}" => policy
  }
}