# Advanced State Management with OpenTofu

In this webinar, we'll look at advanced strategies for using and manipulating the statefile. If you work with OpenTofu (or Terraform) long enough, you **will** have to repair, modify, or recover state. Guaranteed.

## Remote State

### Context

We’ve taken the modules for our database (DB) and EC2 instance and removed the root module that ties them together. This is a common pattern you may see, especially in situations where you have a shared resource, such as a network or a database. Unless you organize your OpenTofu modules in a single monolith, you'll need to pass references to other resources. This can be done via values, but another option is the [`terraform_remote_state` data source](https://opentofu.org/docs/v1.7/language/state/remote-state-data/), which allows you to reference the `outputs` of another remote module.

### Steps

1. Navigate to the database module directory and deploy it:
    ```bash
    cd code/aws_db_instance
    tofu init
    tofu apply
    ```

2. While it runs, examine the `aws_instance` module code:
    - It now takes variables for database info, using those variables to generate `user_data`.

3. Consider the problem of securely providing database details like the password:
    - Options include command-line input, prompting, or `.tfvars` files, all of which have issues.
      - command line is error prone, requires users to have sensitive values, and stores sensistive values in command history
      - using the prompts is very error prone, requires users to have sensitive values, and doesn't work in automation
      - using a `.tfvars` file will likely require the file (and sensitive values) to be checked into source control
    - Instead, use the `terraform_remote_state` to securely fetch only the necessary outputs.

4. Add a `terraform_remote_state` block to reference the state:
    ```hcl
    data "terraform_remote_state" "db" {
      backend = "local"
      config = {
        path = "../aws_db_instance/terraform.tfstate"
      }
    }

    locals {
      user_data = <<-EOF
                  #!/bin/bash
                  yum update -y
                  amazon-linux-extras install docker -y
                  service docker start
                  usermod -a -G docker ec2-user
                  docker run -d \
                    -e WORDPRESS_DB_HOST=${data.terraform_remote_state.db.outputs.endpoint} \
                    -e WORDPRESS_DB_USER=${data.terraform_remote_state.db.outputs.username} \
                    -e WORDPRESS_DB_PASSWORD=${data.terraform_remote_state.db.outputs.password} \
                    -e WORDPRESS_DB_NAME=${data.terraform_remote_state.db.outputs.db_name} \
                    -p 80:80 ${var.image.name}:${var.image.tag}
                EOF
    }
    ```

5. Deploy the `aws_instance` module
    ```bash
    cd ../aws_instance
    tofu init
    tofu apply
    ```

### Drawbacks of Remote State
- **Security:** State files contain all resource data. OpenTofu only allows you to use `outputs`, but you will need read access to the entire file.
- **Hidden Monolith:** Dependencies between modules are one-sided, making them hidden to the module being referenced.
- **Immutability Issues:** Deleting and/or modifying outputs can break referencing modules.

---

## Import Resources

### Context

You might encounter scenarios where:
1. Existing resources (created via the console, cloud CLI/SDK or other tools) need to be managed with OpenTofu.
2. State files are lost or corrupted.

This section will demonstrate how you can import existing resources into your OpenTofu state file.

### Import Process

1. Change directory into the `aws_db_instance` module.
    ```bash
    cd ../aws_db_instance
    ```

2. Rename or remove the statefile.
    ```bash
    mv .terraform.tfstate .terraform.tfstate.old
    ```

3. Use `tofu import` to add a security group back into the state file:
    ```bash
    tofu import aws_security_group.this <security_group_id>
    ```

4. Use the declarative `import` block for the database instance:
    ```hcl
    import {
      to = aws_db_instance.this
      id = var.name_prefix
    }
    ```
5. Comment out the `aws_vpc_security_group_ingress_rule` and `aws_vpc_security_group_egress_rule`. We'll deal with them a little differently.

6. Apply:
    ```bash
    tofu apply
    ```

### Code Generation for Complex Resources

We're going to demonstrate the code generation feature on the security group rules.

1. Add import blocks with known IDs:
    ```hcl
    import {
      to = aws_vpc_security_group_ingress_rule.http
      id = <security group rule id>
    }

    import {
      to = aws_vpc_security_group_egress_rule.http
      id = <security group rule id>
    }
    ```

2. Generate code with:
    ```bash
    tofu plan -generate-config-out=security_groups.tf
    ```

3. Review and refine the generated file as needed before applying. You can keep the new file (and delete the commented out rules) or delete the generated file.

4. Apply:
    ```bash
    tofu apply
    ```

---

## Moving and Renaming Resources

### Context

Refactoring often involves renaming resources or restructuring modules. OpenTofu may interpret these changes as deletion and recreation unless explicitly directed.

### Renaming Resources

1. Change directory into the `aws_instance` module.
    ```bash
    cd ../aws_instance
    ```

2. Change the resource name of the `aws_instance` from `this` to `webserver` in your configuration:
    ```hcl
    resource "aws_instance" "webserver" {
      # configuration
    }
    ```

3. Move the resource in the state file. You may also need to update `outputs`:
    ```bash
    tofu state mv aws_instance.this[0] aws_instance.webserver[0]
    tofu apply
    ```

### Restructuring Counts or Loops

For changes like removing `count`:

1. Update the configuration.
    ```hcl
    resource "aws_instance" "webserver" {
      //count = 1
      ...
    }
    ```

2. Run:
    ```bash
    tofu state mv aws_instance.webserver[0] aws_instance.webserver
    tofu apply
    ```

---

## Migrating Resources to New Types

### Context

Resource deprecation or provider updates may require migrating resources to newer types. For example, replacing `aws_security_group_rule` with `aws_vpc_security_group_ingress_rule`.

### Steps

1. Update the resource configuration:
    ```hcl
    resource "aws_vpc_security_group_ingress_rule" "http" {
      security_group_id = aws_security_group.this.id
      from_port         = 80
      to_port           = 80
      ip_protocol       = "tcp"
      cidr_ipv4         = "0.0.0.0/0"
    }

    resource "aws_vpc_security_group_egress_rule" "all" {
      security_group_id = aws_security_group.this.id

      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
    ```

2. Remove the old resource from state:
    ```bash
    tofu state rm aws_security_group_rule.http_ingress
    tofu state rm aws_security_group_rule.all_egress
    ```

3. Import the new resource:
    ```bash
    tofu import aws_vpc_security_group_ingress_rule.http <id>
    tofu import aws_vpc_security_group_egress_rule.all <id>
    ```

4. Apply changes:
    ```bash
    tofu apply
    ```

---

## Conclusion

By mastering these advanced state management techniques, you can:
- Reference remote state securely.
- Recover and manage resources via imports.
- Refactor and migrate resources efficiently.

These tools are essential for maintaining robust and scalable infrastructure with OpenTofu.

--- 
