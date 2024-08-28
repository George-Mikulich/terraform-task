output "bucket_id" {
  value       = google_storage_bucket.default.name
  description = "Bucket ID. Subject to paste to providers.tf"
}