# Kubernetes Mutating Webhook for Sidecar Injection

This tutoral shows how to build and deploy a *MutatingAdmissionWebhook* that injects a nginx sidecar container into pod prior to persistence of the object.

```
kubectl api-versions | grep admissionregistration.k8s.io
```
The result should be:
```
admissionregistration.k8s.io/v1
admissionregistration.k8s.io/v1beta1
```

> Note: In addition, the `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` admission controllers should be added and listed in the correct order in the admission-control flag of kube-apiserver.

## Build

1. Build binary

```
# make build
```

2. Build docker image
   
```
# make build-image
```

3. push docker image

```
# make push-image
```

> Note: log into the docker registry before pushing the image.

## Deploy

1. Create namespace `sidecar-injector` in which the sidecar injector webhook is deployed:

```
kubectl create ns sidecar-injector
```

2. Create a signed cert/key pair and store it in a Kubernetes `secret` that will be consumed by sidecar injector deployment:

```
./deployment/webhook-create-signed-cert.sh \
    --service sidecar-injector-webhook-svc \
    --secret sidecar-injector-webhook-certs \
    --namespace sidecar-injector
```

3. Patch the `MutatingWebhookConfiguration` by set `caBundle` with correct value from Kubernetes cluster:

```
cat deployment/mutatingwebhook.yaml | \
    deployment/webhook-patch-ca-bundle.sh > \
    deployment/mutatingwebhook-ca-bundle.yaml
```

4. Deploy resources:

```
kubectl create -f deployment/nginxconfigmap.yaml
kubectl create -f deployment/configmap.yaml
kubectl create -f deployment/deployment.yaml
kubectl create -f deployment/service.yaml
kubectl create -f deployment/mutatingwebhook-ca-bundle.yaml
```

## Verify

1. The sidecar inject webhook should be in running state:

```
kubectl -n sidecar-injector get pod
kubectl -n sidecar-injector get deploy
```

2. Create new namespace `injection` and label it with `sidecar-injector=enabled`:

```
kubectl label namespace default sidecar-injection=enabled
kubectl get namespace -L sidecar-injection
```

3. Deploy an app in Kubernetes cluster, take `alpine` app as an example

```
kubectl run alpine --image=alpine --restart=Never -n injection --overrides='{"apiVersion":"v1","metadata":{"annotations":{"sidecar-injector-webhook.morven.me/inject":"yes"}}}' --command -- sleep infinity
```

4. Verify sidecar container is injected:

```
kubectl get pod
```
