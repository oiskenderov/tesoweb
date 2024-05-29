# AWS S3 Bucket Resource

resource "aws_s3_bucket" "demo-bucket" {
  bucket = var.my_bucket_name # Name of the S3 Bucket
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.demo-bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.demo-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# AWS S3 bucket ACL resource
resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.demo-bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "host_bucket_policy" {
  bucket =  aws_s3_bucket.demo-bucket.id # ID of the S3 bucket

  # Policy JSON for allowing public read access
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : [
	   "s3:GetObject",
	   "s3:PutObject",
	]
        "Resource": "arn:aws:s3:::${var.my_bucket_name}/*"
      }
    ]
  })
}

module "template_files" {
    source = "hashicorp/dir/template"

    base_dir = "${path.module}/out/"
}

# https://registry.terraform.io/modules/hashicorp/dir/template/latest


resource "aws_s3_bucket_website_configuration" "web-config" {
  bucket = aws_s3_bucket.demo-bucket.id  # ID of the S3 bucket

  # Configuration for the index document
  index_document {
    suffix = "index.html"
  }
}

# AWS S3 object resource for hosting bucket files
resource "aws_s3_object" "Bucket_files" {
  bucket = aws_s3_bucket.demo-bucket.id  # ID of the S3 bucket

  for_each     = module.template_files.files
  key          = each.key
  content_type = each.value.content_type

  source  = each.value.source_path
  content = each.value.content

  # ETag of the S3 object
  etag = each.value.digests.md5
}


locals {
  s3_bucket_name = var.my_bucket_name
  domain         = "test.teso.az"
  hosted_zone_id = var.hosted_zone_var
  cert_arn       = var.cert_arn_id
}

resource "aws_cloudfront_distribution" "demo-bucket" {
  enabled = true
  aliases = [local.domain]
  default_root_object = "index.html"
  is_ipv6_enabled = true
  wait_for_deployment = true

  
  default_cache_behavior {
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["GET", "HEAD", "OPTIONS"]
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    target_origin_id = aws_s3_bucket.demo-bucket.id
    viewer_protocol_policy = "redirect-to-https"

  }


  origin {
    domain_name = aws_s3_bucket.demo-bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.demo-bucket.id
    origin_id   = aws_s3_bucket.demo-bucket.bucket
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = local.cert_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method = "sni-only"   
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_control" "demo-bucket" {
  name = "s3-cloudfront-test"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

data "aws_iam_policy_document" "aws_cloudfront_oac_access" {
  statement {
    principals {
      identifiers = ["cloudfront.amazonaws.com"]
      type = "Service"
    }

    actions = ["s3:GetObjects"]
    resources = ["${aws_s3_bucket.demo-bucket.arn}/*"]
  }
    
}
resource "aws_cloudfront_origin_access_identity" "demo-bucket" {
  comment = "Access Identity for S3 bucket"
}

