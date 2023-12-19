provider "google" {
  project     = "akiva-sandbox"
  region      = "us-central1" 
}

resource "google_sql_database_instance" "instance" {
  provider = google-beta
  project = "akiva-sandbox"
  name             = "phase4-db"
  region           = "us-central1"
  database_version = "POSTGRES_13"

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled                                  = true
    }
  }
}

#Create a Cloud SQL database (PostgreSQL)
resource "google_sql_database" "app_database" {
  name     = "app-database"
  instance = google_sql_database_instance.instance.name
}

# Create a Cloud SQL user (PostgreSQL)
resource "google_sql_user" "app_db_user" {
  name     = "app-db-user"
  instance = google_sql_database_instance.instance.name
  password = "pass" 
}

resource "google_artifact_registry_repository" "my-repository" {
  location      = "us-central1"
  repository_id = "phase4-repo"
  description   = "docker repository"
  format        = "DOCKER"
}

resource "google_container_cluster" "primary" {
  name     = "phase4-cluster"
  location = "us-central1"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  location   = "us-central1"
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-standard-4"

    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

