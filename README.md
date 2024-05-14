# Terraform Modules for AWS by Healthcare Blocks

Terraform modules with defaults (mostly) centered around HIPAA compliance.

## Documentation

Module documentation is in the [wiki](https://github.com/HealthcareBlocks/hcblocks-terraform-modules-aws/wiki).

Examples are provided in the [examples](examples) directory.

## Prerequisites

- Terraform 1.8 ([install](https://developer.hashicorp.com/terraform/install))
- [AWS credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration) (but don't embed secret access keys in code!)

## Tips

- Set the `TF_PLUGIN_CACHE_DIR` ENV var to a location under your home directory to maintain a single copy of each provider version

## Submitting Pull Requests

- Ensure any [examples](examples) that depend on the proposed functionality do not break
- Provide meaningful changelog text
- Apply a release label (major, minor, no-release, patch) which will automatically set the proper semantic version

## Credits

Repo structure based on [@krukowskid](https://github.com/krukowskid)'s [@terraform-modules-monorepo-on-github](https://github.com/krukowskid/terraform-modules-monorepo-on-github)

Several modules are based on functionality present in https://github.com/terraform-aws-modules