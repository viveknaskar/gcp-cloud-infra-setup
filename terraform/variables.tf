variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region for resources."
  type        = string
  default     = "asia-south1" # Example default, change as needed
}

# Add other variables for resource sizes, names, etc.