# main.tf

provider "aws" {
  region = "" # Change this to your desired region
}

variable "bucket_name" {
  description = "The name of the S3 bucket for the website"
  type        = string
}
variable "github_token" {
  description = "GitHub OAuth token"
  type        = string
  sensitive   = true
}
variable "github_repo_owner" {
  description = "GitHub repository owner"
  type        = string
}
variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
}
variable "github_location" {
  description = "GitHub repository url location"
  type        = string
}

# S3 Bucket
resource "aws_s3_bucket" "website_bucket" {
  bucket = var.bucket_name 

  tags = {
    Name = "WebsiteBucket"
  }
}

# S3 Block public access (bucket settings)
resource "aws_s3_bucket_public_access_block" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


# S3 Website Configuration
resource "aws_s3_bucket_website_configuration" "website_configuration" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {

    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.website_bucket
  ]
}

# S3 Bucket for CodePipeline artifacts
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "${var.bucket_name}-artifacts"



  tags = {
    Name = "CodePipelineArtifacts"
  }
}


# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for S3 bucket"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.website_bucket.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for S3 website"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.website_bucket.id
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "WebsiteDistribution"
  }
}


# Pipeline 

#  IAM ROLES FOR Pipeline


# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline-policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject"
      ]
      Effect   = "Allow"
      Resource = [
        "${aws_s3_bucket.codepipeline_artifacts.arn}",
        "${aws_s3_bucket.codepipeline_artifacts.arn}/*",
        "${aws_s3_bucket.website_bucket.arn}",
        "${aws_s3_bucket.website_bucket.arn}/*"
      ]
    },
    {
       Action = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    Effect = "Allow"
    Resource = ["${aws_codebuild_project.main.arn}"]
  }]

    
  })
}

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "codebuild-policy"
  role   = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

#  Code build Project
resource "aws_codebuild_project" "main" {
  name          = "my-codebuild-project"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
        type = "NO_ARTIFACTS"

  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type            = "GITHUB"
    location = "${var.github_location}"
    git_clone_depth = 1

     git_submodules_config {
      fetch_submodules = true
    }
  }

    source_version = "main"

}


# CodePipeline

resource "aws_codepipeline" "main" {
  name     = "my-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_repo_owner
        Repo       = var.github_repo_name
        Branch     = "main"
        OAuthToken = var.github_token
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.main.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        BucketName = aws_s3_bucket.website_bucket.bucket
        Extract    = "true"
      }
    }
  }
}


output "s3_bucket" {
  value = aws_s3_bucket.website_bucket.bucket
  description = "Name of the of the s3 bucket"
}

output "cloudfront_distribution" {
  value = aws_cloudfront_distribution.website_distribution.domain_name
  description = "dns name of the cloudfront distribution"
}
