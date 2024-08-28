# Google Cloud Platform project ID
variable "GOOGLE_PROJECT" {
  type        = string
  default     = "kbot-429800"
  description = "GCP project to use"
}

# Google Cloud Platform region
variable "GOOGLE_REGION" {
  type        = string
  default     = "us-central1-c"
  description = "GCP Region to use"
}

# GitHub account or organization name
variable "GITHUB_OWNER" {
  type        = string
  description = "GitHub owner repository to use"
}

# GitHub personal access token for authentication
variable "GITHUB_TOKEN" {
  type        = string
  description = "Github personal access token"
}

# Name of the GitHub repository for Flux GitOps
variable "FLUX_GITHUB_REPO" {
  type        = string
  default     = "flux-gitops"
  description = "Flux GitOps repository"
}

# Subdirectory within the Flux GitOps repository for storing cluster manifests
variable "FLUX_GITHUB_TARGET_PATH" {
  type        = string
  default     = "clusters"
  description = "Flux manifest subdirectory"
}
