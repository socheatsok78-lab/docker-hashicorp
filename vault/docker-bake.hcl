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

target "vault_base" {
  context = "base"
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
  tags = [
    "ghcr.io/${GITHUB_REPOSITORY_OWNER}/vault:base-cacheonly"
  ]
}
target "vault" {
  inherits = [
    "docker-metadata-action",
    "github-metadata-action",
  ]
  context = "${VERSION}"
  contexts = {
    "vault" = "target:vault_base"
  }
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
  labels = {
    "org.opencontainers.image.description" = "A tool for secrets management, encryption as a service, and privileged access management"
    "org.opencontainers.image.version" = VERSION
  }
  tags = [
    "ghcr.io/${GITHUB_REPOSITORY_OWNER}/vault:${VERSION}"
  ]
}
