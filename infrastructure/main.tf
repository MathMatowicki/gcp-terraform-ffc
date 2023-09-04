#Bucket to store website

resource "google_storage_bucket" "website" {
    name = "example-webiste-by-mat"
    location = ""
}