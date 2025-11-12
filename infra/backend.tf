terraform {
  backend "gcs" {
    bucket         = "terraform-bkp"
    prefix         = "terraform/gke"
    # Enable state locking with Firestore
  }
}
