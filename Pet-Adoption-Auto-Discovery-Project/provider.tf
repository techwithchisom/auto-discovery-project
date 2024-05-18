provider "aws" {
  region  = "eu-west-3"
  profile = "default"
}

provider "vault" {
  token   = "s.iL9LieBBt8YuPRX7atgz0ylR"
  address = "https://vault.chisomproject.click"
}