# ####################################################################################################
# 1. 테라폼 실행 환경 설정 블록
# ====================================================================================================
# 이 프로젝트에서 사용할 테라폼 자체의 설정과 필요한 플러그인들을 정의합니다.
terraform {
  # 프로젝트에서 사용할 클라우드 제공자(Provider) 목록을 정의합니다.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
#   backend "s3" {
#     bucket         = "instructor-ex-bucket"                                # 위에서 만든 S3 버킷 이름
#     key            = "TerraformState/Ex/remote-backend/terraform.tfstate"  # 버킷 내 저장 경로
#     region         = "ap-south-1"                                          # 리전
#     dynamodb_table = "instructor-ex-terraform-lock-table"                  # DynamoDB 테이블 이름
#     encrypt        = true                                                  # 상태 파일 암호화 여부
#   }
}

# AWS 프로바이더 설정 블록
provider "aws" {
  region = "ap-south-1" 
}


# ####################################################################################################
# 2.상태값 저장을 위한 S3 Bucket 생성
# ====================================================================================================
# S3 버킷 생성
resource "aws_s3_bucket" "terraform_state" {
  bucket = "instructor-ex-bucket" # 전 세계 유일한 이름으로 변경 필요

  lifecycle {
     prevent_destroy = true # 실수로 삭제되는 것을 방지
  }
}

# 버킷 버전 관리 활성화 (상태 복구용)
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ####################################################################################################
# 3.상태 잠금용 DynamoDB 테이블 생성
# ====================================================================================================
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "instructor-ex-terraform-lock-table"
 # 테이블의 비용 지불 방식 및 처리 성능 관리 모드
  billing_mode   = "PROVISIONED" # PROVISIONED(사용할 성릉 예약), PAY_PER_REQUEST(쓴 만큼 지불)
  read_capacity  = 20 # RCU(초당 4KB 데이터 1개 읽기) --> 1RCU
  write_capacity = 20 # WCU(초당 1KB 데이터 1개 읽기) --> 1WCU
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
