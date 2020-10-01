variable "common" {
  type = map(string)
  default = {
    prefix   = "isseeeeey55"
    env      = "dev"
    key_name = "aws-isseeeeey55-ap-northeast-1"
  }
}

variable "zones" {
  type = list(string)
  default = [
    "ap-northeast-1a",
    "ap-northeast-1c",
    "ap-northeast-1d",
  ]
}