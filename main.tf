module "tls_private_key" {
  source    = "github.com/andrey-ilin/tf-hashicorp-tls-keys"
  algorithm = "RSA"
}

module "github_repository" {
  source                   = "github.com/andrey-ilin/tf-github-repository"
  github_owner             = var.GITHUB_OWNER
  github_token             = var.GITHUB_TOKEN
  repository_name          = var.FLUX_GITHUB_REPO
  repository_visibility    = "private"
  public_key_openssh       = module.tls_private_key.public_key_openssh
  public_key_openssh_title = "flux0"
}

module "gke_cluster" {
  source           = "github.com/andrey-ilin/tf-google-gke-cluster"
  GOOGLE_REGION    = var.GOOGLE_REGION
  GOOGLE_PROJECT   = var.GOOGLE_PROJECT
  GKE_MACHINE_TYPE = "e2-highmem-2"
  GKE_NUM_NODES    = 1
}

# Use for local test, uncomment if needed and comment module "gke_cluster" to avoid real infra creation
# module "kind_cluster" {
#   source = "github.com/andrey-ilin/tf-kind-cluster"
# }

resource "local_file" "kubeconfig" {
  content  = module.gke_cluster.kubeconfig
  filename = "${path.module}/kubeconfig"
}

resource "null_resource" "flux_prerequisites" {
  depends_on = [
    module.github_repository,
    module.gke_cluster,
    local_file.kubeconfig
  ]

  triggers = {
    always_run = "${timestamp()}"
  }
}

module "flux_bootstrap" {
  source            = "github.com/andrey-ilin/tf-fluxcd-flux-bootstrap"
  github_repository = "${var.GITHUB_OWNER}/${var.FLUX_GITHUB_REPO}"
  github_token      = var.GITHUB_TOKEN
  private_key       = module.tls_private_key.private_key_pem
  config_path       = module.gke_cluster.kubeconfig

  # config_path = module.kind_cluster.kubeconfig
  depends_on_hack = null_resource.flux_prerequisites.id
}

terraform {
  backend "gcs" {
    bucket = "tf-storage-test"
    prefix = "terraform/state"
  }
}
