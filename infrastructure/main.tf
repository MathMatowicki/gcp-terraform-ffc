#Bucket to store website

resource "google_storage_bucket" "website" {
  name     = "example-webiste-by-mat"
  location = "EU"
}

#Make new object public
resource "google_storage_object_access_control" "public_rule" {
  object = google_storage_bucket_object.static_site_src.name
  bucket = google_storage_bucket.website.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_storage_object_access_control" "public_second_rule" {
  object = google_storage_bucket_object.static_site_logoasset.name
  bucket = google_storage_bucket.website.name
  role   = "READER"
  entity = "allUsers"
}

#Upload html file and asset to the bucket
resource "google_storage_bucket_object" "static_site_src" {
  name   = "index.html"
  source = "../website/index.html"
  bucket = google_storage_bucket.website.name
}

resource "google_storage_bucket_object" "static_site_logoasset" {
  name   = "cropped-mathmatowickilogo.png"
  source = "../website/cropped-mathmatowickilogo.png"
  bucket = google_storage_bucket.website.name
}

#Reserve static external IP address
resource "google_compute_global_address" "website" {
  name = "website-lb-ip"
}

#Get the managed DNS Zone
data "google_dns_managed_zone" "dns_zone" {
  name = "mmatowicki-zone-name"
}

#Add the IP to the DNS 
resource "google_dns_record_set" "website" {
  provider     = google
  name         = "website.${data.google_dns_managed_zone.dns_zone.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.dns_zone.name
  rrdatas      = [google_compute_global_address.website.address]
}

#Add the bucket as a CDN backend
resource "google_compute_backend_bucket" "website-backend" {
  provider    = google
  name        = "website-bucket"
  bucket_name = google_storage_bucket.website.name
  description = "Contains files needed for the website"
  enable_cdn  = true
}

# Create HTTPS certificate
resource "google_compute_managed_ssl_certificate" "website" {
  name = "website-ssl-cert"
  managed {
    domains = [google_dns_record_set.website.name]
  }
}

#GCP URL MAP
resource "google_compute_url_map" "webiste" {
  name            = "webiste-url-map"
  default_service = google_compute_backend_bucket.website-backend.self_link
  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.website-backend.self_link
  }
}

#GCP HTTP Proxy
resource "google_compute_target_http_proxy" "website" {
  name    = "webiste-target-proxy"
  url_map = google_compute_url_map.webiste.self_link
}

# GCP forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  name                  = "website-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website.address
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.website.self_link
}
