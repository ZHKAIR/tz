# Terralist Helm Chart

This Helm chart deploys Terralist - a Terraform Registry implementation.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure (if persistence is enabled)

## Installation

### Quick Start

1. Copy and customize the application values:
```bash
cp app-terralist.yaml my-values.yaml
# Edit my-values.yaml with your specific configuration
```

2. Install the chart:
```bash
helm install terralist ./helm-chart -f values-common.yaml -f my-values.yaml
```

### Configuration

The chart uses a layered configuration approach:

1. **values.yaml** - Default values (don't edit this)
2. **values-common.yaml** - Common configuration shared across environments
3. **app-terralist.yaml** - Application-specific values (copy and customize this)

#### Important Configuration Options

##### Authentication (Required)
```yaml
config:
  auth:
    oauth:
      clientId: "your-oidc-client-id"
      clientSecret: "your-oidc-client-secret"
      issuerUrl: "https://your-keycloak-domain.com/realms/your-realm"
    cookieSecret: "change-me-to-32-character-secret-minimum-length"
    tokenSigningSecret: "change-me-to-secure-secret"
```

##### S3 Storage (Required for module storage)
```yaml
config:
  s3:
    enabled: true
    endpoint: "s3.amazonaws.com"
    bucketName: "terralist-modules"
    bucketRegion: "us-east-1"
    accessKeyId: "your-access-key-id"
    secretAccessKey: "your-secret-access-key"
```

##### Persistence
```yaml
persistence:
  enabled: true
  storageClass: "standard"  # Change to your storage class
  size: 5Gi
```

##### Ingress
```yaml
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: terralist.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: terralist-tls
      hosts:
        - terralist.example.com
```

### Upgrade

```bash
helm upgrade terralist ./helm-chart -f values-common.yaml -f my-values.yaml
```

### Uninstall

```bash
helm uninstall terralist
```

## Known Issues

- **Security Context**: Due to a bug in Terralist v0.8.0, security context must be disabled. Do not enable `podSecurityContext` or `containerSecurityContext`.

## Persistence

When persistence is enabled:
- SQLite database is stored at `/mnt/data/terralist.db`
- Data survives pod restarts
- Init container sets proper permissions on the data directory

When persistence is disabled:
- Database is stored at `/tmp/terralist.db`
- Data is lost when pod restarts

## Monitoring

The chart includes Prometheus annotations by default:
```yaml
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "5758"
  prometheus.io/path: "/metrics"
```

## Support

For issues related to:
- Chart: Create an issue in this repository
- Terralist: Visit https://github.com/terralist/terralist