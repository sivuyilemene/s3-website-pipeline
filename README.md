# AWS S3 React Website Hosting with CloudFront Distribution and CI/CD Pipeline

This Terraform script automates the creation of a highly available and scalable static website hosting solution on AWS. It leverages:

- **S3**: For storing website files
- **CloudFront**: As a CDN for improved performance and security
- **CodePipeline**, **,CodeBuild**, **GitHub**,: To implement a CI/CD pipeline for automated website deployments

## Prerequisites

1. **Terraform**: Installed on your local machine. (Get started: [https://learn.hashicorp.com/terraform/getting-started/install.html])
2. **AWS account**:  With sufficient permissions to create S3 buckets, CloudFront distributions, IAM roles, and CodePipeline/CodeBuild resources.
3. **GitHub repository**:  with a `buildspec.yml` file in the root directory.

## Getting Started

### 1. Clone the Repository

Clone this repository to your local machine.

```bash
git clone https://github.com/sivuyilemene/s3-website-pipeline.git
cd s3-website-pipeline/
```

### 2. Create a GitHub Personal Access Token

Follow these steps to create a GitHub personal access token:

1. Log in to your GitHub account.
2. Go to Settings > Developer settings > Personal access tokens.
3. Click Generate new token.
4. Set a descriptive name, expiration date, and select the required scopes:
    - `repo` (Full control of private repositories)
    - `admin:repo_hook` (Full control of repository hooks)
5. Click Generate token and copy the token.

- Save the token securely.

### 3. Configure Terraform Variables

Create a `terraform.tfvars` file in the project root and add the following variables:

```bash
bucket_name       = "your-bucket-name"
github_token      = "your-generated-token"
github_repo_owner = "your-repo-owner"
github_repo_name  = "your-repo-name"
github_location = "your-github-url"
```

### 4. Initialize and Apply Terraform Configuration

Initialize Terraform:

```bash
terraform init
```

Apply the Terraform configuration:

```bash
terraform apply
```

Follow the prompts and type `yes` to confirm the creation of the resources.

## File Structure

- `main.tf`: The main Terraform configuration file.
- `terraform.tfvars`: A file to store variable values (not included in the repository).
- `buildspec.yml`: The build specification file for CodeBuild (should be in your GitHub repository).

## Components

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.website_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_origin_access_identity.oai](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_identity) | resource |
| [aws_codebuild_project.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codepipeline.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline) | resource |
| [aws_iam_role.codebuild_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.codepipeline_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.codebuild_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.codepipeline_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_s3_bucket.codepipeline_artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.website_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.website_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.website_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_website_configuration.website_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | The name of the S3 bucket for the website | `string` | n/a | yes |
| <a name="input_github_location"></a> [github\_location](#input\_github\_location) | GitHub repository url location | `string` | n/a | yes |
| <a name="input_github_repo_name"></a> [github\_repo\_name](#input\_github\_repo\_name) | GitHub repository name | `string` | n/a | yes |
| <a name="input_github_repo_owner"></a> [github\_repo\_owner](#input\_github\_repo\_owner) | GitHub repository owner | `string` | n/a | yes |
| <a name="input_github_token"></a> [github\_token](#input\_github\_token) | GitHub OAuth token | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudfront_distribution"></a> [cloudfront\_distribution](#output\_cloudfront\_distribution) | n/a |
| <a name="output_s3_bucket"></a> [s3\_bucket](#output\_s3\_bucket) | n/a |
<!-- END_TF_DOCS -->

### S3 Bucket

- `Website Bucket`: Stores the static website files.
- `Artifacts Bucket`: Stores the CodePipeline artifacts.

### CloudFront Distribution

Distributes the content from the S3 website bucket.
Uses an Origin Access Identity (OAI) for secure access to the S3 bucket.

### IAM Roles and Policies

Roles and policies for CodePipeline and CodeBuild to access necessary AWS services.

### CodePipeline

- **Source Stage**: Retrieves source code from the GitHub repository.
- **Build Stage**: Uses CodeBuild to build the project based on the buildspec.yml file.
- **Deploy Stage**: Deploys the built artifacts to the S3 website bucket.

### CodeBuild

A CodeBuild project configured to use the buildspec.yml file from the GitHub repository.

### Outputs (After Deployment)

Terraform will output:

- S3 Bucket: The name of the S3 website bucket.
- CloudFront Distribution Domain Name: The URL to access your live website.

## Clean Up

To delete all resources created by this Terraform configuration, run:

```bash
terraform destroy
```

Confirm the deletion by typing `yes` when prompted.

## Additional Notes

- Domain Name: To use a custom domain (e.g., `www.yourdomain.com`), you'll need to configure DNS settings to point to your CloudFront distribution.
- SSL/TLS Certificates: For HTTPS, obtain a certificate (e.g., from AWS Certificate Manager) and associate it with your CloudFront distribution.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
