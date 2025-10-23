variable "GITHUB_REPOSITORY_OWNER" {
  default = "socheatsok78-lab"
}

target "docker-metadata-action" {}
target "github-metadata-action" {}

group "default" {
  targets = [
    "consul",
    "vault",
    "openbao",
  ]
}

# --------------------------------------------------
# HashiCorp Consul
# --------------------------------------------------

variable "CONSUL_VERSIONS" {
  type = list(string)
  default = [
    // "1.21.3",
    // "1.21.4",
    "1.21.5",
  ]
}
target "consul-base" {
  context = "consul/base"
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
  tags = [
    "ghcr.io/${GITHUB_REPOSITORY_OWNER}/consul:base-cacheonly"
  ]
}
target "consul" {
  matrix = {
    version = CONSUL_VERSIONS
  }
  name = "consul_${sanitize(version)}"
  inherits = [
    "docker-metadata-action",
    "github-metadata-action",
  ]
  context = "consul/${version}"
  contexts = {
    "consul" = "target:consul-base"
  }
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
  labels = {
    "org.opencontainers.image.description" = "Consul is a distributed, highly available, and data center aware solution to connect and configure applications across dynamic, distributed infrastructure."
    "org.opencontainers.image.version" = version
  }
  tags = [
    "ghcr.io/${GITHUB_REPOSITORY_OWNER}/consul:${version}"
  ]
}

# --------------------------------------------------
# HashiCorp Vault
# --------------------------------------------------

variable "VAULT_VERSIONS" {
  type = list(string)
  default = [
    // "1.20.0",
    // "1.20.1",
    // "1.20.2",
    // "1.20.3",
    "1.20.4",
    "1.21.0",
  ]
}
target "vault-base" {
  context = "vault/base"
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
  tags = [
    "ghcr.io/${GITHUB_REPOSITORY_OWNER}/vault:base-cacheonly"
  ]
}
target "vault" {
  matrix = {
    version = VAULT_VERSIONS
  }
  name = "vault_${sanitize(version)}"
  inherits = [
    "docker-metadata-action",
    "github-metadata-action",
  ]
  context = "vault/${version}"
  contexts = {
    "vault" = "target:vault-base"
  }
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
  labels = {
    "org.opencontainers.image.description" = "A tool for secrets management, encryption as a service, and privileged access management"
    "org.opencontainers.image.version" = version
  }
  tags = [
    "ghcr.io/${GITHUB_REPOSITORY_OWNER}/vault:${version}"
  ]
}

# --------------------------------------------------
# Openbao
# --------------------------------------------------

variable "OPENBAO_VERSIONS" {
  type = list(string)
  default = [
    // "2.4.0",
    "2.4.1",
    "2.4.2",
  ]
}
target "openbao-base" {
  context = "openbao/base"
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
  tags = [
    "ghcr.io/${GITHUB_REPOSITORY_OWNER}/openbao:base-cacheonly"
  ]
}
target "openbao" {
  matrix = {
    version = OPENBAO_VERSIONS
  }
  name = "openbao_${sanitize(version)}"
  inherits = [
    "docker-metadata-action",
    "github-metadata-action",
  ]
  context = "openbao/${version}"
  contexts = {
    "openbao" = "target:openbao-base"
  }
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
  labels = {
    "org.opencontainers.image.description" = "A tool for secrets management, encryption as a service, and privileged access management"
    "org.opencontainers.image.version" = version
  }
  tags = [
    "ghcr.io/${GITHUB_REPOSITORY_OWNER}/openbao:${version}"
  ]
}
