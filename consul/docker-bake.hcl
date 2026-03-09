variable "VERSION" {
  default = ""
  validation {
    condition = VERSION != ""
    error_message = "The variable 'VERSION' must be set to a non-empty value."
  }
}

variable "GITHUB_REPOSITORY_OWNER" {
  default = "socheatsok78-lab"
}

target "docker-metadata-action" {}
target "github-metadata-action" {}

target "consul_base" {
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
  inherits = [
    "docker-metadata-action",
    "github-metadata-action",
  ]
  context = "consul/${VERSION}"
  contexts = {
    "consul" = "target:consul_base"
  }
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
  labels = {
    "org.opencontainers.image.description" = "Consul is a distributed, highly available, and data center aware solution to connect and configure applications across dynamic, distributed infrastructure."
    "org.opencontainers.image.version" = VERSION
  }
  tags = [
    "ghcr.io/${GITHUB_REPOSITORY_OWNER}/consul:${VERSION}"
  ]
}
