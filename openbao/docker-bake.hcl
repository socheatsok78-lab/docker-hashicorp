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

variable "OPENBAO_VERSIONS" {
  type = list(string)
  default = [
    "2.4.0",
    "2.4.1",
    "2.4.2",
    "2.4.3",
    "2.4.4",
    "2.5.0",
    "2.5.1",
  ]
}
target "openbao_base" {
  context = "base"
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
  tags = [
    "ghcr.io/${GITHUB_REPOSITORY_OWNER}/openbao:base-cacheonly"
  ]
}
target "openbao" {
  inherits = [
    "docker-metadata-action",
    "github-metadata-action",
  ]
  context = "${VERSION}"
  contexts = {
    "openbao" = "target:openbao_base"
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
    "ghcr.io/${GITHUB_REPOSITORY_OWNER}/openbao:${VERSION}"
  ]
}
