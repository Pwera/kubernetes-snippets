# Connaisseur

sigstore is a Linux Foundation project that aims to provide public software signing and transparency to improve open source supply chain security. As part of the sigstore project, Cosign allows seamless container signing, verification and storage. You can read more about it here.

Connaisseur currently supports the elementary function of verifying Cosign-generated signatures based on the following types of keys:
- Locally-generated key pair
- KMS (via reference URI or export of the public key)
- Hardware-based token (export the public key)

Generate `cosign.pub` & `cosign.key`
```bash
cosign generate-key-pair
```

Download connaisseur 
```bash
git clone https://github.com/sse-secure-systems/connaisseur.git
cd connaisseur
```

To use Connaisseur with Cosign, configure a validator in helm/values.yaml with the generated public key (cosign.pub) as a trust root. The entry in .application.validators should look something like this (make sure to add your own public key to trust root default):
```yaml
- name: customvalidator
  type: cosign
  trustRoots:
    - name: default
      key: | 
      -----BEGIN PUBLIC KEY-----
      -----END PUBLIC KEY-----
```
Install connaisseur
```bash
helm install connaisseur helm --atomic --create-namespace --namespace connaisseur
```

Try to deploy this unsigned image: 
```bash
IMAGE=pwera/wrk:latest
kubectl run test --image=${IMAGE}
```

Sign the image
```bash
cosign sign --key cosign.key ${IMAGE}
```

Verify signature
```bash
cosign verify --key cosign.pub ${IMAGE}

Verification for index.docker.io/pwera/wrk:latest --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key


```

Deploy signed image:
```bash
kubectl run test --image=${IMAGE}
```