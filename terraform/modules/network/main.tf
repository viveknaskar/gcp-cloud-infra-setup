resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
  project                 = var.gcp_project_id
}

resource "google_compute_subnetwork" "subnets" {
  for_each      = { for s in var.subnet_configs : s.name => s }
  name          = each.value.name
  ip_cidr_range = each.value.ip_cidr_range
  region        = each.value.region
  network       = google_compute_network.vpc_network.self_link
  dynamic "private_ip_google_access" {
    for_each = lookup(each.value, "private_ip_google_access", false) ? [1] : []
    content {
      enable = true
    }
  }
  dynamic "secondary_ip_range" {
    for_each = lookup(each.value, "secondary_ip_range", [])
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
  # Add purpose and role for private service access (Cloud SQL)
  purpose = lookup(each.value, "purpose", null)
  role    = lookup(each.value, "role", null)
}

resource "google_compute_router" "nat_router" {
  name    = "${var.network_name}-nat-router"
  region  = var.gcp_region
  network = google_compute_network.vpc_network.self_link
  project = var.gcp_project_id
}

resource "google_compute_router_nat" "nat_config" {
  name                          = "${var.network_name}-nat-config"
  router                        = google_compute_router.nat_router.name
  region                        = google_compute_router.nat_router.region
  nat_ip_allocate_option        = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
  project = var.gcp_project_id
}

# Cloud DNS example
resource "google_dns_managed_zone" "private_zone" {
  name        = "internal-zone"
  dns_name    = "internal.example.com." # Replace with your internal domain
  description = "Private DNS zone for internal services"
  visibility  = "private"
  private_visibility_config {
    network_urls = [google_compute_network.vpc_network.self_link]
  }
  project = var.gcp_project_id
}

# Firewall rules, Cloud Armor, and Load Balancer would also go in this module or separate ones.