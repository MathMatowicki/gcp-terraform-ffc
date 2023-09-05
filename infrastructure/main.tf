#Bucket to store website

resource "google_storage_bucket" "website" {
    name = "example-webiste-by-mat"
    location = "EU"
}

#Make new object public
resource "google_storage_object_access_control" "public_rule" {
    object = google_storage_bucket_object.static_site_src.name
    bucket = google_storage_bucket.website.name
    role = "READER"
    entity = "allUsers"
}

resource "google_storage_object_access_control" "public_second_rule" {
    object = google_storage_bucket_object.static_site_logoasset.name
    bucket = google_storage_bucket.website.name
    role = "READER"
    entity = "allUsers"
}

#Upload html file and asset to the bucket
resource "google_storage_bucket_object" "static_site_src" {
    name =  "index.html"
    source = "../webiste/index.html"
    bucket = google_storage_bucket.website.name
}

resource "google_storage_bucket_object" "static_site_logoasset" {
    name =  "cropped-mathmatowickilogo.png"
    source = "../website/cropped-mathmatowickilogo.png"
    bucket = google_storage_bucket.website.name
}
