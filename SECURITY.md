# 🛡️ Security Policy

## 📦 Environment Configuration & Secrets Management

All sensitive configurations are securely handled using **Kubernetes Secrets** within the `prometheus` namespace.

### 🔧 Creating Secrets
Create secrets from `.env` files with:

```bash
kubectl create secret generic <name> \
  --from-env-file=<path/to/env> \
  -n prometheus --dry-run=client -o yaml | kubectl apply -f -
```

### 🔐 Secrets in Use
- `auth-secret`: `k8s/config/auth-config.env`
- `discounts-secret`: `k8s/config/discounts-config.env`
- `frontend-secret`: `k8s/config/frontend-config.env`
- `items-secret`: `k8s/config/items-config.env`
- `aws-creds`: static AWS credentials for exporting logs to S3

### 🗂️ ConfigMaps in Use
- `haproxy-config`: HAProxy routing & SSL configuration
- `loki-export-script`: log export script used by CronJob for S3 uploads

> ⚠️ Secrets are managed via CI/CD pipelines or authorized admin access only. Never committed to version control.

---

## 🔐 TLS & HTTPS Enforcement

All external-facing traffic is secured via **TLS**, with **HAProxy** as the ingress controller.

### 📄 TLS Certificate Setup

Concatenate and securely store TLS certificates:

```bash
cat haproxy.crt haproxy.key > haproxy.pem
sudo mv haproxy.pem /etc/ssl/private/
```

Create Kubernetes secret from the certificate:

```bash
kubectl create secret generic haproxy-tls \
  --from-file=haproxy.pem=/k8s/ssl/haproxy.pem \
  -n prometheus
```

Apply HAProxy configuration via ConfigMap:

```bash
kubectl create configmap haproxy-config \
  --from-file=restauranty/haproxy.cfg \
  -n prometheus
```

### 🔁 Certificate Lifecycle

Manage TLS certs with **ACM** or **Certbot**:

```bash
sudo apt update
sudo apt install certbot
```

Auto-renewal via `cron` or `systemd` timers.

---

## 🔒 GitHub Actions Secrets

Secrets used in CI/CD workflows are managed securely through **GitHub Actions Secrets**.

> Examples: API keys, deployment credentials, AWS tokens, etc.

---

✅ Ensure regular rotation and review of all secrets.

---

🧠 Need more help? [Security Best Practices](https://kubernetes.io/docs/concepts/configuration/secret/)
