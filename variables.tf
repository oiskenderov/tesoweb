variable "my_bucket_region" {
    description = "my default bucket region"
    type = string
    default = "us-west-1"
}

variable "my_bucket_name" {
    description = "my bucket name"
    type = string
    default = "orkhanapp"
}

variable "cert_arn_id" {
    description = "my east certficate"
    type = string
    default = "arn:aws:acm:us-east-1:218220018863:certificate/43a169c9-a116-4952-827f-4d7acb4a9e0c"
}

variable "hosted_zone_var" {
    description = "my hosted zone"
    type = string
    default = "Z09831852FL88FQ1R79QL"
}
