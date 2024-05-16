terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.40"
    }
  }
  required_version = ">= 1.8.0"
}