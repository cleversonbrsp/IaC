Aqui está o texto revisado com ajustes para melhor fluidez e clareza:  

---

Você deve ter baixado e instalado a OCI CLI versão 2.24.0 (ou superior) e configurado corretamente. Se a sua versão da OCI CLI for anterior à 2.24.0, faça o download e instale uma versão mais recente [aqui](#). Caso não tenha certeza da versão instalada, verifique com o seguinte comando:  

```sh
oci -v
```

### 1. Criar diretório para o kubeconfig  

Para armazenar o arquivo de configuração do kubeconfig, crie o diretório necessário:  

```sh
mkdir -p $HOME/.kube
```

### 2. Gerar o kubeconfig do cluster  

- **Para acesso via endpoint público:**  

```sh
oci ce cluster create-kubeconfig --cluster-id ocid1.cluster.oc1.sa-saopaulo-1.aaaaaaaauhpbdbxqgvl7dbokt33p6otriep24ugd5o62xi42bcbblbjy7isa \
  --file $HOME/.kube/config \
  --region sa-saopaulo-1 \
  --token-version 2.0.0 \
  --kube-endpoint PUBLIC_ENDPOINT
```

- **Para acesso via endpoint privado:**  

```sh
oci ce cluster create-kubeconfig --cluster-id ocid1.cluster.oc1.sa-saopaulo-1.aaaaaaaauhpbdbxqgvl7dbokt33p6otriep24ugd5o62xi42bcbblbjy7isa \
  --file $HOME/.kube/config \
  --region sa-saopaulo-1 \
  --token-version 2.0.0 \
  --kube-endpoint PRIVATE_ENDPOINT
```

### 3. Definir a variável de ambiente KUBECONFIG  

Para garantir que o kubeconfig seja utilizado corretamente pelo `kubectl`, defina a variável de ambiente:  

```sh
export KUBECONFIG=$HOME/.kube/config
```

Caso queira salvar o kubeconfig em um local diferente, modifique o argumento `--file` no comando da CLI acima. Se necessário, atualize o seu script de inicialização do shell para persistir a variável `KUBECONFIG`.  

Para mais informações sobre o gerenciamento de arquivos kubeconfig, consulte a [documentação oficial do Kubernetes](#). Além disso, você pode encontrar mais detalhes sobre os comandos disponíveis na CLI do Container Engine for Kubernetes da OCI [aqui](#).  

---

Fiz ajustes para deixar o texto mais objetivo, removi repetições e padronizei os comandos. Me avise se precisar de mais alguma modificação! 🚀