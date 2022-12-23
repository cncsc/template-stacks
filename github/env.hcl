locals {
  env = yamldecode(file("env.yaml"))
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "github" {
  owner = "${local.env.name}"
}
EOF
}

inputs = {
  github_org = "${local.env.name}"
}
