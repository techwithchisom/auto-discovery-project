provider "aws" {
  region  = "eu-west-3"
  profile = "team1"
}

provider "vault" {
  token   = "s.iL9LieBBt8YuPRX7atgz0ylR"
  address = "https://vault.tundeafod.click"
}