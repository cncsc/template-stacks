# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

locals {
  remote_state_config = yamldecode(file(".remote-state-config.yaml"))
  workspace           = replace(replace("${path_relative_to_include()}", "/[^A-Za-z0-9]/", "-"), "/(-[-]+)/", "-")
}

// Configure hook to validate the Terraform Cloud workspace is configured for local execution
terraform {
  before_hook "validate_tfc_workspace" {
    commands = ["import", "plan", "apply", "destroy"]
    execute  = ["/bin/bash", "${get_terragrunt_dir()}/${path_relative_from_include()}/.tools/verify-tfc-workspace.sh", "${local.remote_state_config.organization}", "${local.workspace}"]
  }
}

// Generate the remote state backend config
generate "remote_state" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "remote" {
    hostname     = "${local.remote_state_config.hostname}"
    organization = "${local.remote_state_config.organization}"

    workspaces {
      name = "${local.workspace}"
    }
  }
}
EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL PARAMETERS
# These variables apply to all configurations in this subfolder. These are automatically merged into the child
# `terragrunt.hcl` config via the include block.
# ---------------------------------------------------------------------------------------------------------------------

inputs = {
  remote_state_config = merge(local.remote_state_config, { workspace = local.workspace })
}
