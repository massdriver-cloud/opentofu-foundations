# Week 7: Multi Environment Management

## Introduction

In this session we will learn how to manage multiple deployments with the same OpenTofu configuration. We will learn about workspaces which are OpenTofu's built in mechanism for managing multiple state backends. Next we will cover some tricks to make managing workspaces less error prone for users. Lastly we will look at Checkov and how to implement security and policy scanning to ensure your deployments meet your compliance needs.

## Why Bother with IaC?

To this point we have covered a lot of how, but have neglected the why. It is important to remind ourselves how we even ended up with this technology. If we forget the horrors of the past, it will come back to bite us.

### A Trip In the Technology Time Machine

The story really starts in 1993 with the release of CFEngine. Mark Burgess was managing a collections of workspaces in a Physics lab. Mark's time was being stolen manually fixing and scripting solutions on these workspaces which were running different flavors of UNIX. To manage the problem Mark created a declarative system that would allow him to declare what the working state of the system is, and CFEngine would make it so. This is the first instance of configuration as code.

Not until 2009 with the release of Chef do we see this declarative approach to server management gain wide adoption. Chef introduced a full programming language to extend the declarative DSL. Chef was built with a client/server architecture which was perfect for the dawn of EC2 3 years prior where servers were no longer hardware that sits in your data center.

AWS continues to force innovation with the release of managed services and serverless. Now configuration could be spread out across your entire cloud account. You have linux sysadmin problems at datacenter scale. Not surprisingly the first release of Terraform and public access to AWS Lambda happen within months of eachother in 2014.

With the smarts conatined in more and more sophisticated orchestration systems like Kubernetes and ECS, declarative management is absolutely crucial.

### Why Not Click Around In The Console?

Cloud native systems are complex. The time between first creating a staging environment to full production release can be months or years. Will you really remember which buttons you pushed? Which IAM roles were necessary? Did you open that security group up to the world for a reason? You need reproducibility in the cloud. Everything is ephemeral so you can spin up a whole environment in the event that something malfunctions in a region. In the event of an outage are you going to remember the magical console incantation? Probably not.

The other major advantage to IaC and the tools we will cover today is parity. When working with dev, staging, and production, you want confidence that the changes in staging will actually work in production. To ensure that is the case, you want your environment to be structurally the same. However we do not want to run at the same level of scale that powers our production environments in our internal testing environments. This is where OpenTofu workspaces shine.

```bash
cd week-7/code
tofu init -var-file default.auto.tfvars
```

As we can see our backend is remote and we have minimal changes.

```bash
tofu workspace list
```

As you can see OpenTofu automatically creates a default workspace. When handling a single deployment of your IaC this is sufficient. We will however be managing staging and production. Let's create our first workspace for staging.

```bash
tofu workspace new staging
tofu plan -var-file default.auto.tfvars
```

As we can see OpenTofu wants to create all of our resources over again. Workspaces prefix the key in our backend configuration. The key is now prefixed with our workspace name giving us the ability to stamp out duplicate infrastructure in parity. We can not run apply though because it would fail due to naming collisions. Let's handle this by creating a new tfvars file for our workspace.

```bash
touch staging.auto.tfvars
echo 'name_prefix = "wk7-dave"' >> staging.auto.tfvars
tofu plan -var-file staging.auto.tfvars
```

This fixed the naming collisions we were going to see, but the tags are wrong as this is no longer the dev environment. Using the `terraform.workspace` variable we can add tags to the environment. We can add a locals block with a ternary to pull the environment from. This will help us handle backwards compatibility with the default workspace.

```terraform
locals {
  environment = terraform.workspace == "default" ? "dev" : terraform.workspace
  environment_name_segment = terraform.workspace == "default" ? "" : "${terraform.workspace}-"
}
```

Now we can set the environment using our local so it reflects what workspace owns the resource

```terraform
provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      environment = local.environment 
      project     = "opentofu-foundations"
    }
  }
}
```

Lets add the workspace name to the aws_db_instance, and aws_instance name as well

```terraform
module "aws_db_instance" {
  source = "github.com/massdriver-modules/otf-shared-modules//modules/aws_db_instance?ref=main"

  name_prefix = "${var.name_prefix}-${local.environment_name_segment}db"
  db_name     = "wordpress"
  username    = "admin"
  password    = "yourpassword" # In production, use a secure method for passwords

  tags = {
    Owner = "YourName"
  }
}

module "aws_instance" {
  source = "github.com/massdriver-modules/otf-shared-modules//modules/aws_instance?ref=main"

  name_prefix   = "${var.name_prefix}-${local.environment_name_segment}instance"
  instance_type = "t2.micro"

  user_data = <<-EOF
                #!/bin/bash
                yum update -y
                amazon-linux-extras install docker -y
                service docker start
                usermod -a -G docker ec2-user
                docker run -d \
                  -e WORDPRESS_DB_HOST=${module.aws_db_instance.endpoint} \
                  -e WORDPRESS_DB_USER=${module.aws_db_instance.username} \
                  -e WORDPRESS_DB_PASSWORD=${module.aws_db_instance.password} \
                  -e WORDPRESS_DB_NAME=${module.aws_db_instance.db_name} \
                  -p 80:80 ${var.image.name}:${var.image.tag}
              EOF

  tags = {
    Owner = "YourName"
  }
}
```

Once we have a better differentiator for environments, we can change the instance name back because it is likely a project name which we would want in parity.

```
name_prefix = "wk5-cory"
```

```bash
tofu plan -var-file staging.auto.tfvars
```

We can see the changes reflected in our plan. Let's apply it and look at the state file

```bash
tofu apply -var-file staging.auto.tfvars
```

We now see a new directory in our bucket, `env:/`. This is a default prefix that is applied when using non default workspaces. Inside that directory we see `staging/` this is the name of our workspace. Nested under our workspace identifier we see the `wordpress/` directory which begins our set key in the s3 backend configuration. Your workspace default prefix can be overridden in the backend configuration with the `workspace_key_prefix` attribute.


## Making Prod

Just like staging, lets make a production workspace

```bash
touch production.auto.tfvars
echo 'name_prefix = "wk5-cory"' >> production.auto.tfvars
tofu plan -var-file production.auto.tfvars
```

Now that we have a production workspace, we will want to serve our wordpress blog on a larger instance than our internal staging deployment. Let's declare a variable so we can set an instance type.

```terraform
variable wordpress_instance_type {
  type = string
}

variable db_instance_class {
  type = string
}

module "aws_db_instance" {
  source = "github.com/massdriver-modules/otf-shared-modules//modules/aws_db_instance?ref=main"

  name_prefix = "${var.name_prefix}-${local.environment_name_segment}db"
  db_name     = "wordpress"
  username    = "admin"
  password    = "yourpassword" # In production, use a secure method for passwords
  instance_class = var.db_instance_class

  tags = {
    Owner = "YourName"
  }
}

module "aws_instance" {
  source = "github.com/massdriver-modules/otf-shared-modules//modules/aws_instance?ref=main"

  name_prefix   = "${var.name_prefix}-${local.environment_name_segment}instance"
  instance_type = var.wordpress_instance_type 

  user_data = <<-EOF
                #!/bin/bash
                yum update -y
                amazon-linux-extras install docker -y
                service docker start
                usermod -a -G docker ec2-user
                docker run -d \
                  -e WORDPRESS_DB_HOST=${module.aws_db_instance.endpoint} \
                  -e WORDPRESS_DB_USER=${module.aws_db_instance.username} \
                  -e WORDPRESS_DB_PASSWORD=${module.aws_db_instance.password} \
                  -e WORDPRESS_DB_NAME=${module.aws_db_instance.db_name} \
                  -p 80:80 ${var.image.name}:${var.image.tag}
              EOF

  tags = {
    Owner = "YourName"
  }
}
```

Now add your values in your tfvars files to verify backwards compatability in the default workspace

```terraform
name_prefix = "wk5-cory"
wordpress_instance_type = "t2.micro"
db_instance_class = "db.t3.micro"
```

```terraform
tofu workspace select default
tofu plan -var-file default.auto.tfvars
```

Looks like it will not make any changes in default. Let's do the same in staging.

```terraform
name_prefix = "wk5-cory"
wordpress_instance_type = "t2.micro"
db_instance_class = "db.t3.micro"
```

```terraform
tofu workspace select staging
tofu plan -var-file staging.auto.tfvars
```

With the plan clean in staging we can do the same in production. Let's also increase the size of the instances in production

```terraform
name_prefix = "wk5-cory"
wordpress_instance_type = "t3.micro"
db_instance_class = "db.t3.small"
```

```terraform
tofu workspace select production
tofu plan -var-file production.auto.tfvars
```

## Workspace Automation

As you can see we are doing a lot of juggling. We have multiple tfvars files, multiple state backends. This is a recipe for a serious problem. Let's do some quick automation to make this whole thing easier. The quickest path is our old friend make.

```bash
touch Makefile
```

```make
.PHONY: prod.plan default.plan staging.plan
default.plan:
	tofu workspace select default
	tofu plan -var-file=default.auto.tfvars
	
prod.plan:
	tofu workspace select production
	tofu plan -var-file=production.auto.tfvars

staging.plan:
	tofu workspace select staging
	tofu plan -var-file=staging.auto.tfvars

.PHONY: staging.deploy prod.deploy default.deploy
staging.deploy:
	tofu workspace select staging
	tofu apply -var-file=staging.auto.tfvars

prod.deploy:
	tofu workspace select production
	tofu apply -var-file=production.auto.tfvars

default.deploy:
	tofu workspace select default
	tofu apply -var-file=default.auto.tfvars
```

We have no created an abstraction around OpenTofu commands which ensures that we are at a minimum using the correct variable files with the correct workspaces which reduces the chances of user error. Let's test the functionality by planning default

```bash
make default.plan
```

## Governance

Now that we have the ability to deploy to multiple environments we need some form of governance in place to ensure that our infrastructure is secure in production. We can also implement checks for things like instance types in non production so large instances aren't running up the AWS bill when they are not required.

To enable these checks we will use Checkov in our pipelines. Checkov runs by taking a plan generated by OpenTofu and running that plan against some predefined security rules. Let's add Checkov now.

```make
prod.plan:
	tofu workspace select production
	tofu plan -var-file=production.auto.tfvars -out ./production.plan
  tofu show -json production.plan  > production.json
  checkov -f production.json
  rm production.json production.plan
```

```bash
make prod.plan
```

As we can see there are a bunch of checks that are being run, some of which pass and some of which fail. This will give us a clear idea of our security posture. Let's ignore the failing checks in our default workspace.

```make
default.plan:
  tofu workspace select default
  tofu plan -var-file=default.auto.tfvars -out ./default.plan
  tofu show -json default.plan > default.json
  checkov -f default.json \
    --skip-check CKV_AWS_16,CKV_AWS_133,CKV_AWS_293,CKV_AWS_354,CKV_AWS_129,CKV_AWS_129,CKV_AWS_157,CKV_AWS_118,CKV_AWS_79,CKV_AWS_8,CKV_AWS_88,CKV_AWS_135,CKV_AWS_126,CKV_AWS_79,CKV_AWS_88,CKV_AWS_24,CKV_AWS_260,CKV2_AWS_60
  rm default.json default.plan
```

Let's run this now

```bash
make default.plan
```

This is now good enough for a dev environment and all checks are passing.

Let's add a custom policy which will require a t2.micro in environments that are not production.

```bash
touch preprod-policy.yaml
```

```yaml
metadata:
  id: "CKV2_PRE_PROD_INSTANCE_TYPE"
  name: "Ensure instance types are t2.micro"
  category: "CONVENTION"
  severity: "HIGH"
definition:
     cond_type: "attribute"
     resource_types:
     - "aws_instance"
     attribute: "instance_type"
     operator: "equals"
     value: "t2.micro"
```

Lets update the makefile to use this new policy for staging

```make
staging.plan:
  tofu workspace select staging
   tofu plan -var-file=staging.auto.tfvars -out ./staging.plan
  tofu show -json staging.plan > staging.json
  checkov -f staging.json \
    --soft-fail \
    --external-checks-dir . \
    --run-all-external-checks \
    --skip-check CKV_AWS_16,CKV_AWS_133,CKV_AWS_293,CKV_AWS_354,CKV_AWS_129,CKV_AWS_129,CKV_AWS_157,CKV_AWS_118,CKV_AWS_79,CKV_AWS_8,CKV_AWS_88,CKV_AWS_135,CKV_AWS_126,CKV_AWS_79,CKV_AWS_88,CKV_AWS_24,CKV_AWS_260,CKV2_AWS_60
  rm staging.json staging.plan
```

Finally update your staging tfvars to violate this policy

```terraform
wordpress_instance_type = "t3.micro"
```

```bash
make staging.plan
```

As we can see our custom policy has failed

```bash
Check: CKV2_PRE_PROD_INSTANCE_TYPE: "Ensure instance types are t2.micro"
        FAILED for resource: module.aws_instance.aws_instance.this[0]
        Severity: HIGH
        File: /staging.json:0-0
```

## The Path to a Platform

As you can see all of this workspace juggling is a challenge. Imagine having to manage an unknown number of environments with feature branches or preview environments. Imagine you are tasked with creating blueprints for a company that buy's media companies and runs thousands of Wordpress instances. What would you have to do in that case?

- We will no longer have the bandwidth to be involved in every new infrastructure deployment. We will need a central hub where others can securely deploy infrastructure.
- We don't want to be in the business of managing vars files for each environment? How can we remove that from our perview?
- We need to maximize OpenTofu's capabilities as blueprints. We should be able to stamp out well crafted infrastructure without having to write more OpenTofu.
- We need to eliminate pipelines as a blocker to delivering infrastructure.
- We need to package security and validation in our blueprints to ensure end users can have confidence in what they are deploying.