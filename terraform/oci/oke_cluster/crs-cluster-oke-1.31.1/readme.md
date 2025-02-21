Você deve ter baixado e instalado a OCI CLI versão 2.24.0 (ou superior) e configurado corretamente. Se a sua versão da OCI CLI for anterior à 2.24.0, faça o download e instale uma versão mais recente. Caso não tenha certeza da versão instalada, verifique com o seguinte comando:  

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

---
### **Sobre o provisionamento do Dynamic Group

O OCID do compartimento do OKE (`oci_identity_compartment.oke_comp.id`) só está disponível depois que ele é provisionado, precisamos ajustar a **Dynamic Group** para contornar essa limitação.  

Infelizmente, o **`matching_rule` exige um valor estático**, então **não pode depender de recursos do Terraform**. Mas há uma alternativa:  
- Você pode **executar o Terraform em duas etapas**:  
  1. **Criar o compartimento (`oci_identity_compartment.oke_comp`)** e obter seu OCID.  
  2. **Executar um segundo `terraform apply`**, agora que o OCID já está disponível, para criar a Dynamic Group corretamente.  

---

### **Opção 1: Duas Execuções (`terraform apply` em etapas)**
1. Execute o Terraform **apenas até provisionar o compartimento**:
   ```sh
   terraform apply -target=oci_identity_compartment.oke_comp
   ```
2. Copie o OCID gerado e adicione manualmente no `matching_rule` do **Dynamic Group**.
3. Execute o Terraform novamente para criar a Dynamic Group e a Policy:
   ```sh
   terraform apply
   ```

**Vantagem:** Funciona sem precisar modificar o código.  
**Desvantagem:** Exige uma execução manual extra.

---

### **Opção 2: Definir a Dynamic Group Manualmente**
Outra abordagem seria criar o **Dynamic Group diretamente pelo console da OCI**, usando o OCID do compartimento após provisioná-lo. Assim, o Terraform não precisaria gerenciá-lo.

**Vantagem:** Evita complicações no Terraform.  
**Desvantagem:** Exige um passo manual na configuração inicial.

---

### **Opção 3: Usar um Script para Automatizar**
Se quiser manter tudo automatizado, você pode rodar um **script Terraform + OCI CLI** para:
1. Criar o compartimento (`terraform apply -target=oci_identity_compartment.oke_comp`).
2. Obter o OCID via **OCI CLI**:
   ```sh
   oci iam compartment get --compartment-id <compartment_ocid>
   ```
3. Atualizar dinamicamente o Terraform para incluir o OCID no `matching_rule`.
4. Rodar `terraform apply` novamente.

Isso poderia ser feito via um script Bash, PowerShell ou mesmo um módulo no Terraform.  

---

### **Conclusão**
Se o objetivo é **manter tudo no Terraform**, então **a melhor alternativa é executar o `terraform apply` em duas etapas**. Não há como referenciar diretamente `oci_identity_compartment.oke_comp.id` no `matching_rule`, pois a OCI exige um valor fixo.  

Se quiser algo mais automatizado, um **script com a OCI CLI** pode resolver isso. 🚀

---

### **Testar o Cluster Autoscaler**

Para testar o **Cluster Autoscaler** no **Oracle Kubernetes Engine (OKE)**, você pode simular uma carga alta no cluster de algumas maneiras, forçando a criação de novos nós quando os recursos forem insuficientes. Aqui estão os principais métodos:

---

### 🚀 **1. Criando PODs que Consomem Muitos Recursos**
A maneira mais direta de testar o autoscaler é criar **Pods que consomem muita CPU e memória**, forçando o OKE a escalar novos nós.

📌 **Crie um deployment com muitos recursos**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stress-test
spec:
  replicas: 5  # Aumente para estressar mais o cluster
  selector:
    matchLabels:
      app: stress
  template:
    metadata:
      labels:
        app: stress
    spec:
      containers:
      - name: stress-ng
        image: polinux/stress
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1Gi"
        command: ["stress"]
        args: ["--cpu", "2", "--vm", "2", "--vm-bytes", "512M", "--timeout", "300s"]
```
📌 **O que esse deployment faz?**
- Ele cria 5 réplicas de um container usando a imagem `polinux/stress`
- Cada POD vai usar **2 vCPUs** e **512MB de memória**, forçando o cluster a escalar novos nós quando os recursos atuais forem insuficientes.

🔹 **Aumente os valores** para consumir mais recursos e testar a escalabilidade do cluster.

---

### 🔄 **2. Usando o HPA (Horizontal Pod Autoscaler)**
Se o **HPA** estiver habilitado no seu cluster, você pode configurar um autoscaler para aumentar o número de réplicas automaticamente.

📌 **Crie um HPA para o Deployment acima**:
```sh
kubectl autoscale deployment stress-test --cpu-percent=50 --min=5 --max=20
```
Isso fará com que o Kubernetes aumente as réplicas do **stress-test** quando o uso de CPU ultrapassar 50%.

---

### 🔥 **3. Gerando Carga com um Job de Teste**
Você pode usar **`kubectl run`** para criar um pod que executa um teste de carga no cluster.

```sh
kubectl run stress-cpu --image=busybox --restart=Never -- /bin/sh -c "yes > /dev/null &"
```
Esse comando cria um Pod que usa CPU indefinidamente, ajudando a testar o autoscaler.

---

### 📈 **4. Monitorando o Escalonamento**
Após rodar os testes, monitore se novos nós estão sendo adicionados ao cluster:

📌 **Veja os nós do cluster**:
```sh
kubectl get nodes
```
📌 **Acompanhe os pods e réplicas**:
```sh
kubectl get pods -o wide
kubectl get hpa
```
📌 **Acompanhe os eventos do cluster**:
```sh
kubectl get events --sort-by=.metadata.creationTimestamp
```

---

### 🚀 **Conclusão**
Com esses testes, você deve ver o **OKE escalando automaticamente os nós** do cluster quando os pods começarem a consumir mais CPU e memória. Quando a carga diminuir, os nós extras devem ser removidos.

Fontes:
https://docs.oracle.com/pt-br/iaas/Content/ContEng/Tasks/contengusingclusterautoscaler.htm
https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/oci/README.md
https://docs.oracle.com/en/cloud/paas/weblogic-container/user/create-dynamic-groups-and-policies.html
https://docs.oracle.com/en-us/iaas/Content/Identity/compartments/Working_with_Compartments.htm#Working

