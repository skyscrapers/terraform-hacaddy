# terraform-hacaddy

Terraform module to setup all resources needed for a HA Caddy setup. To be used in conjunction with the `roles::hacaddy` Puppet role.
This module is tailered very specific for Skyscrapers environments

## Available variables

  * [`project`]: String(required): The name of the project.
  * [`environment`]: String(required): The name of the environment (production, staging , development).
  * [`proxyname`]: String(optional, default "proxy"): Name to use for the proxy setup.
  * [`vpc_id`]: String(required): VPC ID where the proxies will be deployed.
  * [`subnet_count`]: Number(required): Number of subnets (to deploy de instances and for EFS targets).
  * [`subnet_ids`]: List(string)(required): Subnet IDs where the proxies will be deployed. Also use as EFS targets.
  * [`sg_all_id`]: String(required): ID of the base security group.
  * [`ami`]: String(required): AMI to be used for the proxy instances.
  * [`key_name`]: String(required): ID of the SSH key to use for the proxy instances.
  * [`instance_type`] String(optional, default "t2.small"): The instance type to launch for the proxy hosts.
  * [`cpu_credits`] String(optional, default "standard"): The type of cpu credits to use

## Output

  * [`efs_dns_name`]: List(string): DNS name of the EFS volume per target (should be all the same).
  * [`eips`]: List(string): Elastic IPs attached to the proxy instances. At setup you choose 1 to be master and 1 slave.
  * [`instance_ids`]: List(string): IDs of the proxy instances.
  * [`sg_id`]: String: ID of the proxy instances security group.

## Example

```terraform
module "hacaddy" {
  source        = "github.com/skyscrapers/terraform-hacaddy"
  environment   = var.environment
  project       = var.project
  proxyname     = "proxy"
  vpc_id        = module.vpc.vpc_id
  subnet_count  = 3
  subnet_ids    = [module.vpc.public_subnets]
  sg_all_id     = module.securitygroups.sg_all_id
  ami           = "ami-971238f1"
  key_name      = "philip"
  instance_type = "t3.small"
  cpu_credits   = "unlimited"
}
```
