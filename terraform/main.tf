# Configure the Google Cloud provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Data source to fetch current project details
data "google_project" "project" {
  project_id = var.gcp_project_id
}

# Enable required Google APIs
resource "google_project_service" "enabled_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "dns.googleapis.com",
    "containerregistry.googleapis.com", # For image management
    "cloudbuild.googleapis.com",        # For CI/CD
    "cloudbilling.googleapis.com",      # For billing account checks if needed
    "cloudfunctions.googleapis.com",    # If using serverless functions
    "servicenetworking.googleapis.com"  # For Cloud SQL private IP
  ])
  project = var.gcp_project_id
  service = each.key
  disable_on_destroy = false
}

# Example of calling modules for different infrastructure components
module "network" {
  source       = "./modules/network"
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  network_name   = "my-vpc-network"
  subnet_configs = [
    {
      name        = "gke-subnet"
      ip_cidr_range = "10.0.0.0/20"
      region      = var.gcp_region
    },
    {
      name        = "sql-subnet"
      ip_cidr_range = "10.0.16.0/24"
      region      = var.gcp_region
      purpose     = "REGIONAL_MANAGED_PROXY" # For Cloud SQL private IP
      role        = "ACTIVE"
    }
  ]
}

module "gke_cluster" {
  source          = "./modules/gke"
  gcp_project_id  = var.gcp_project_id
  gcp_region      = var.gcp_region
  network_self_link = module.network.network_self_link
  subnetwork_self_link = module.network.gke_subnetwork_self_link
  cluster_name    = "my-gke-cluster"
  node_pool_configs = {
    "default-node-pool" = {
      machine_type    = "e2-medium"
      node_count      = 3
      min_node_count  = 1
      max_node_count  = 5
      disk_size_gb    = 100
      oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    }
  }
}

module "cloud_sql" {
  source         = "./modules/cloud_sql"
  gcp_project_id   = var.gcp_project_id
  gcp_region       = var.gcp_region
  instance_name    = "my-app-db"
  database_version = "POSTGRES_14"
  tier             = "db-f1-micro"
  private_network_self_link = module.network.private_network_self_link
  db_users         = {
    "app_user" = "supersecretpassword"
  }
}

module "iam" {
  source         = "./modules/iam"
  gcp_project_id   = var.gcp_project_id
  gke_service_account_email = module.gke_cluster.gke_service_account_email
}