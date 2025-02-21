resource "oci_containerengine_addon" "addons" {
  addon_name                 = "ClusterAutoscaler"
  cluster_id                       = oci_containerengine_cluster.generated_oci_containerengine_cluster.id
  remove_addon_resources_on_delete = true

  configurations {
    key   = "nodes"
    value   = <<EOL
    1:3:${oci_containerengine_node_pool.create_node_pool_details0.id}
    EOL
  }  

       configurations {
    key   = "maxNodeProvisionTime" #Reduz o tempo para um node ser considerado falho durante o provisionamento
    value = "3m"
}  
      configurations {
    key   = "scaleDownDelayAfterAdd" #Tempo de espera após adição de um novo node ante que ocorra o scale-down
    value = "2m"
  }  
      configurations {
    key   = "scaleDownUnneededTime" #Quanto tempo um node precisa ficar ocioso para ser removido
    value = "2m"
  } 
      configurations {
    key   = "scaleDownUnreadyTime" #Tempo que o node fica em "NotReady" antes de ser designado para remoção
    value = "5m"
  } 
      configurations {
    key   = "scaleDownNonEmptyCandidatesCount" #Ajusta a agressividade do scale-down
    value = "5"
}
      configurations {
    key   = "scaleDownCandidatesPoolRatio" #Ajusta a agressividade do scale-down
    value = "0.1"
}
      configurations {
     key   = "maxGracefulTerminationSec" #Força o delete do node no periodo de 5 minutos
     value = "300"
}

} 