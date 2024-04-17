// Existing Terraform src code found at /tmp/terraform_src.

locals {
  stack_name = "react-cors-spa-stack"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_api_gateway_rest_api" "simple_api" {
  description = "A simple CORS compliant API"
  name        = "SimpleAPI"
  endpoint_configuration {
    types = [
      "REGIONAL"
    ]
  }
}

resource "aws_api_gateway_resource" "simple_api_resource" {
  parent_id   = aws_api_gateway_rest_api.simple_api.root_resource_id
  path_part   = "hello"
  rest_api_id = aws_api_gateway_rest_api.simple_api.arn
}

resource "aws_api_gateway_method" "hello_apiget_method" {
  api_key_required = false
  authorization    = "NONE"
  http_method      = "GET"
  // CF Property(Integration) = {
  //   Type = "MOCK"
  //   PassthroughBehavior = "WHEN_NO_MATCH"
  //   RequestTemplates = {
  //     application/json = "{
  //  "statusCode": 200
  // }"
  //   }
  //   IntegrationResponses = [
  //     {
  //       StatusCode = 200
  //       SelectionPattern = 200
  //       ResponseParameters = {
  //         method.response.header.Access-Control-Allow-Origin = "'*'"
  //       }
  //       ResponseTemplates = {
  //         application/json = "{"message": "Hello World!"}"
  //       }
  //     }
  //   ]
  // }
  // CF Property(MethodResponses) = [
  //   {
  //     StatusCode = 200
  //     ResponseParameters = {
  //       method.response.header.Access-Control-Allow-Origin = true
  //     }
  //     ResponseModels = {
  //       application/json = "Empty"
  //     }
  //   }
  // ]
  rest_api_id = aws_api_gateway_rest_api.simple_api.arn
  resource_id = aws_api_gateway_resource.simple_api_resource.id
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.simple_api.arn
  stage_name  = "v1"
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = {
    ServerSideEncryptionConfiguration = [
      {
        ServerSideEncryptionByDefault = {
          SSEAlgorithm = "AES256"
        }
      }
    ]
  }
  // CF Property(PublicAccessBlockConfiguration) = {
  //   BlockPublicAcls = true
  //   BlockPublicPolicy = true
  //   IgnorePublicAcls = true
  //   RestrictPublicBuckets = true
  // }
  logging {
    target_bucket = aws_s3_bucket.logging_bucket.id
    // CF Property(LogFilePrefix) = "s3-access-logs"
  }
  versioning {
    // CF Property(Status) = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  policy = jsonencode({
    Id      = "MyPolicy"
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "PolicyForCloudFrontPrivateContent"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.s3_bucket.arn}/*"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "AWS:SourceArn" : "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cf_distribution.id}"
          }
        }
        Action = "s3:GetObject*"
      }
    ]
    }
  )
  bucket = aws_s3_bucket.s3_bucket.id
}

resource "aws_s3_bucket" "logging_bucket" {
  bucket = {
    ServerSideEncryptionConfiguration = [
      {
        ServerSideEncryptionByDefault = {
          SSEAlgorithm = "AES256"
        }
      }
    ]
  }
  // CF Property(PublicAccessBlockConfiguration) = {
  //   BlockPublicAcls = true
  //   BlockPublicPolicy = true
  //   IgnorePublicAcls = true
  //   RestrictPublicBuckets = true
  // }
  versioning {
    // CF Property(Status) = "Enabled"
  }
  // CF Property(OwnershipControls) = {
  //   Rules = [
  //     {
  //       ObjectOwnership = "BucketOwnerPreferred"
  //     }
  //   ]
  // }
}

resource "aws_cloudfront_distribution" "cf_distribution" {
  // CF Property(DistributionConfig) = {
  //   Origins = [
  //     {
  //       DomainName = aws_s3_bucket.s3_bucket.region
  //       Id = "myS3Origin"
  //       S3OriginConfig = {
  //         OriginAccessIdentity = ""
  //       }
  //       OriginAccessControlId = aws_cloudfront_origin_access_control.cloud_front_origin_access_control.id
  //     },
  //     {
  //       DomainName = "${aws_api_gateway_rest_api.simple_api.arn}.execute-api.${data.aws_region.current.name}.amazonaws.com"
  //       Id = "myAPIGTWOrigin"
  //       CustomOriginConfig = {
  //         OriginProtocolPolicy = "https-only"
  //       }
  //     }
  //   ]
  //   Enabled = "true"
  //   DefaultRootObject = "index.html"
  //   DefaultCacheBehavior = {
  //     AllowedMethods = [
  //       "GET",
  //       "HEAD",
  //       "OPTIONS"
  //     ]
  //     TargetOriginId = "myS3Origin"
  //     CachePolicyId = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  //     OriginRequestPolicyId = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
  //     ResponseHeadersPolicyId = "67f7725c-6f97-4210-82d7-5512b31e9d03"
  //     ViewerProtocolPolicy = "redirect-to-https"
  //   }
  //   CacheBehaviors = [
  //     {
  //       PathPattern = "v1/hello"
  //       AllowedMethods = [
  //         "GET",
  //         "HEAD",
  //         "OPTIONS"
  //       ]
  //       TargetOriginId = "myAPIGTWOrigin"
  //       CachePolicyId = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  //       OriginRequestPolicyId = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  //       ResponseHeadersPolicyId = "67f7725c-6f97-4210-82d7-5512b31e9d03"
  //       ViewerProtocolPolicy = "redirect-to-https"
  //     }
  //   ]
  //   PriceClass = "PriceClass_All"
  //   Logging = {
  //     Bucket = aws_s3_bucket.logging_bucket.region
  //     Prefix = "cloudfront-access-logs"
  //   }
  //   ViewerCertificate = {
  //     CloudFrontDefaultCertificate = true
  //     MinimumProtocolVersion = "TLSv1.2_2021"
  //   }
  // }
}

resource "aws_cloudfront_origin_access_control" "cloud_front_origin_access_control" {
  origin_access_control_origin_type = {
    Description                   = "Default Origin Access Control"
    Name                          = local.stack_name
    OriginAccessControlOriginType = "s3"
    SigningBehavior               = "always"
    SigningProtocol               = "sigv4"
  }
}

output "api_endpoint" {
  value = "https://${aws_api_gateway_rest_api.simple_api.arn}.execute-api.${data.aws_region.current.name}.amazonaws.com/v1/hello"
}

output "bucket_name" {
  value = "react-cors-spa-${aws_api_gateway_rest_api.simple_api.arn}"
}

output "cf_distribution_url" {
  value = aws_cloudfront_distribution.cf_distribution.domain_name
}
