provider "aws" {
  region = "us-east-1"
}

#s3 bucket
resource "aws_s3_bucket" "nextjs_blog_bucket" {
  bucket = "jnm-nextjs-blog-bucket"
} 


#Ownership control
#Defines the ownership of the objects inside the bucket. and ensure only the bucket owner has onwernship of objects inside bucket
resource "aws_s3_bucket_ownership_controls" "nextjs_blog_bucket_ownership" {
  bucket = aws_s3_bucket.nextjs_blog_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

#Block public access settings for the bucket.
#Provides a centralized way to manage public access to the bucket and its objects.
resource "aws_s3_bucket_public_access_block" "nextjs_blog_bucket_public_access_block" {
  bucket = aws_s3_bucket.nextjs_blog_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

#Bucket ACL.. set to public read
#Defines access permissions for the bucket and its objects.

resource "aws_s3_bucket_acl" "nextjs_blog_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.nextjs_blog_bucket_ownership,
    aws_s3_bucket_public_access_block.nextjs_blog_bucket_public_access_block
  ]

  bucket = aws_s3_bucket.nextjs_blog_bucket.id
  acl = "public-read"
}

#Bucket policy to allow public read access
resource "aws_s3_bucket_policy" "nextjs_blog_bucket_policy" {
  bucket = aws_s3_bucket.nextjs_blog_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PublicReadGetObject"
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.nextjs_blog_bucket.arn}/*"
      }
    ]
  })
}

#origin Access identity for CloudFront
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "OAI for Next.js Blog Portfolio Site"
}

#CloudFront distribution
resource "aws_cloudfront_distribution" "nextjs_distribution" {
    origin {
        domain_name = aws_s3_bucket.nextjs_blog_bucket.bucket_regional_domain_name
        origin_id   = "S3-nextjs-portfolio-bucket"

        s3_origin_config {
            origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
        }
    }
    enabled = true
    is_ipv6_enabled = true
    comment = "CloudFront distribution for Next.js Blog Portfolio Site"
    default_root_object = "index.html"

    default_cache_behavior {
        target_origin_id = "S3-nextjs-portfolio-bucket"
        viewer_protocol_policy = "redirect-to-https"
        allowed_methods = ["GET", "HEAD", "OPTIONS"]
        cached_methods = ["GET", "HEAD"]

        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }

        min_ttl = 0
        default_ttl = 86400
        max_ttl = 31536000
    }

    viewer_certificate {
        cloudfront_default_certificate = true
    }

    restrictions {  
        geo_restriction {
            restriction_type = "none"
        }

    }
}