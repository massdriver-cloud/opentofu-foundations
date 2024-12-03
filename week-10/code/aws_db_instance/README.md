
<!-- BEGINNING OF PRE-COMMIT-OPENTOFU DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.8 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.68 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.78.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_db_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allocated_storage"></a> [allocated\_storage](#input\_allocated\_storage) | Allocated storage in GB | `number` | `20` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Name of the database | `string` | `"wordpress"` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | Database engine | `string` | `"mariadb"` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Database engine version | `string` | `"10.6.19"` | no |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | Instance class for the DB instance | `string` | `"db.t3.micro"` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Identifier for the database instance | `string` | `"wordpress"` | no |
| <a name="input_password"></a> [password](#input\_password) | Master password for the database | `string` | `"th3Passw0rd"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the database instance | `map(string)` | `{}` | no |
| <a name="input_username"></a> [username](#input\_username) | Master username for the database | `string` | `"admin"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_db_name"></a> [db\_name](#output\_db\_name) | Database name |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | Database endpoint |
| <a name="output_password"></a> [password](#output\_password) | Database master password |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the database security group |
| <a name="output_username"></a> [username](#output\_username) | Database master username |
<!-- END OF PRE-COMMIT-OPENTOFU DOCS HOOK -->
