# Security Policy

## 📦 Environment Configuration and Secrets Management

All environment-specific configurations and secrets are stored securely using Kubernetes Secrets within the `prometheus` namespace.

### Created Secrets:
Secrets are created from environment variable files using:
```bash
kubectl create secret generic <name> \
  --from-env-file=<path/to/env> \
  -n prometheus --dry-run=client -o yaml | kubectl apply -f -
```

#### Secrets in Use:
- `auth-secret`: `k8s/config/auth-config.env`
- `discounts-secret`: `k8s/config/discounts-config.env`
- `frontend-secret`: `k8s/config/frontend-config.env`
- `items-secret`: `k8s/config/items-config.env`

All secrets are created and updated through CI/CD or by authorized admins. Secrets are **never** committed to source control.

---

## 🔐 TLS & HTTPS Enforcement

All external-facing traffic is encrypted using TLS with HAProxy as the ingress controller.

### Certificate Configuration:

TLS certificates are combined and stored securely:
```bash
cat haproxy.crt haproxy.key > haproxy.pem
sudo mv haproxy.pem /etc/ssl/private/
```

Certificates are used to create a secret:
```bash
kubectl create secret generic haproxy-tls \
  --from-file=haproxy.pem=/k8s/ssl/haproxy.pem \
  -n prometheus
```

HAProxy is configured via a configmap:
```bash
kubectl create configmap haproxy-config \
  --from-file=restauranty/haproxy.cfg \
  -n prometheus
```

### Certificate Lifecycle:
ACM or Certbot is used for automated TLS certificate management.

```bash
sudo apt update
sudo apt install certbot
```

Renewal is handled automatically or monitored via cronjobs/systemd timers.

---

## 🔒 GitHub Actions Secrets

All CI/CD secrets are securely managed via **GitHub Actions Secrets**. These include:
