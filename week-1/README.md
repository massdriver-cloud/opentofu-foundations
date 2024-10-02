# Week 1 Course: Introduction to OpenTofu and Basic Commands

Missed the session? Watch [here](https://www.youtube.com/watch?v=bd9AGCT4E18)

## Introduction

Welcome to week one of the [OpenTofu workshop](https://www.massdriver.cloud/blogs/opentofu-foundations---a-free-weekly-workshop-to-build-your-iac-skills)! In this module, you'll learn how to create an EC2 instance running Wordpress, set up a MariaDB database, and configure basic infrastructure in AWS. We’ll go through creating instances, security groups, and databases while discussing key Terraform/OpenTofu concepts.

**Important**: The goal of this session is _not_ to create the most reliable, secure infrastructure. We're trying to do the bare minimum AWS so we can focus on OpenTofu and IaC concepts.

## Course Objectives

- Understand the purpose and benefits of OpenTofu.
- Set up your first OpenTofu project.
- Learn foundational concepts of Infrastructure as Code (IaC).
- Write your first OpenTofu configuration.
- Define basic infrastructure resources like compute instances and networking components.
- Familiarize yourself with common OpenTofu commands: `init`, `plan`, `apply`, and `destroy`.
- Understand providers, resources, variables, and outputs.
- Interpret the output of `tofu plan` to preview infrastructure changes.

## Key Commands

Commands you'll use to manage your infrastructure.

* `tofu init`
* `tofu fmt`
* `tofu validate`
* `tofu plan`
* `tofu apply`

## Prerequisites

- An AWS Account.
- [OpenTofu CLI](https://opentofu.org/docs/intro/install/) installed.

## Walkthrough

### 0. Create module boilerplate

To get started we'll need to make our first module. OpenTofu treats all files ending in `*.tf` in the same directory as a module. 

We'll follow the standard for naming:

```sh
mkdir otf-week-1
cd otf-week-1
touch {main,provider,outputs,variables}.tf
```

### 1. Create an EC2 Instance Running NGINX

#### Step 1.1: Initialize the Instance

To start, we will create an AWS EC2 instance running NGINX, but first we'll need to configure OpenTofu to use AWS.

Providers are abstractions that interact with different cloud providers. There are hundreds of them available to OpenTofu.

Add the following code to `provider.tf`. The first block configures the version of the AWS provider we want to use, 
the second configures our interactions with the AWS API.

This is where you can also configure authentication, but the AWS will default to what is set up in your AWS creds files.

The `provider` keyword is followed by the name of the provider ("aws") and its config. Configuration varies from provider to provider, but this should be enough to get you going using your machine's AWS credentials.

**`provider.tf`**:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.68"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}
```

To download and configure the providers run the following:

```sh
tofu init
```

**Note:** If you add more providers over time or change versions of your providers you'll need to run:

```sh
tofu init -upgrade
```

#### Step 1.2: Build our first EC2 Instance

Below is the HCL for creating our first instance.

The `resource` keyword tells OpenTofu that you want to manage a resource. 

The `"aws_instance"` is the type of the resource in the `"aws"` provider. Note that resources start with their provider name with an `_` infix. 

Resource types don't always map to what the cloud calls them. Finally, we have `"this"` which is the name of this resource _in our code_. It does not control the resource name in the cloud. This is how we will address this resource as we connect components together to make larger infrastructures.

Within the curly braces are "attributes" of the resource, specific to this resource type.

We'll start with running Nginx to keep it simple and swap to Wordpress in a few minutes.

**`main.tf`**:

```hcl
resource "aws_instance" "this" {
  # Amazon Linux 2 AMI
  ami                    = "ami-08578967e04feedea"
  
  # Free Tier: t2.micro 750 hours / month - 12 months
  instance_type          = "t2.micro"
  
  # Useful for demo, wouldn't advise for production workloads
  associate_public_ip_address = true
  
  user_data = <<-EOF
                #!/bin/bash
                yum update -y
                amazon-linux-extras install docker -y
                service docker start
                docker run -d -p 80:80 nginx
              EOF

  tags = {
    Name = "my-instance"
  }              
}
```

<details>
  <summary>Aside: What is an AMI?</summary>

AMI stands for Amazon Machine Image. It is a pre-configured virtual machine image that is used to create EC2 instances in AWS. An AMI contains the operating system, software, and configuration settings required to launch an instance. It serves as a template for creating new instances and can be customized to meet specific requirements. AMIs are stored in Amazon S3 and can be shared with other AWS accounts or made publicly available. They provide a fast and reliable way to provision new instances with the desired software stack and configuration.

List AWS official images
```shell
# list official aws images
aws ec2 describe-images --owners 137112412989 --query 'Images[*].[ImageId,Name,Description]' --output table

# Get details on the image we are using (for your own tinfoil hat curiousity)
aws ec2 describe-images --image-ids ami-08578967e04feedea --query 'Images[*].[ImageId,Name,Description,CreationDate]' --output table
```
</details>

Let's run our first plan:

```sh
tofu plan
```

You should see some output like:

```
OpenTofu will perform the following actions:

  # aws_instance.this will be created
  + resource "aws_instance" "this" {
      + ami                                  = "ami-08578967e04feedea"
      + arn                                  = (known after apply)
      + associate_public_ip_address          = true
      ## OMITTED
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

What is important here is OpenTofu is showing you the type of resource and its name, and the attributes it plans to set. We can see our AMI as well as many attributes labeled "(known after apply)." This means we didnt set a value, but the cloud will set and respond with one, so we'll know it once its applied. :D

Lets make our first instance.

You have to paths you can pick here, the easy one for a tutorial or **"the right way."**

Easy Button: This will create the resources straight away, and how we'll run this the rest of the tutorial for brevity.

```sh
tofu apply -auto-approve
```

If you want to build your resources the right way, you should do so from a "plan." OpenTofu will tell you what it plans to do, but in rapidly changing environments, running plan twice within a few minutes could result in different plans depending on if your teammates or CI have made changes to those resources. Running "plans" gives you a guarantee about what OpenTofu will do, it will do exactly what is _in the plan_.

```sh
tofu plan -out tofu.plan
tofu apply tofu.plan
```

You should see a similar message confirming one resource was added!

```
To perform exactly these actions, run the following command to apply:
    tofu apply "tofu.plan"
aws_instance.this: Creating...
aws_instance.this: Still creating... [10s elapsed]
aws_instance.this: Still creating... [20s elapsed]
aws_instance.this: Still creating... [30s elapsed]
aws_instance.this: Creation complete after 32s [id=i-026c5e5ebf3f198d8]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

**🎉 Congrats, you just created your first cloud resource with OpenTofu!**

---

### 2. Inspecting resources

Once the instance is created, we want to capture and display some information about our infrastructure, for now we'll want the instances AWS ARN (identifier) and the public URL so we can hit our nginx landing page.

Add the following `output` block.

`outputs.tf`

```hcl
output "instance_arn" {
  description = "AWS EC2 Instance ARN"
  value       = aws_instance.this.arn
}

output "instance_url" {
  description = "Public IP URL of the instance"
  value       = "http://${aws_instance.this.public_ip}"
}
```

The `output` keyword adds an entry to the output of the OpenTofu run. The name in quotes will be the key in the output and the `value` attribute will set the value. There are additional attributes you can set on an output like "description" and "sensitive" for masking outputs. It is _not_ a real security measure.

```bash
tofu apply
```

You can access the output at anytime without an apply by running:

```sh
tofu output
# Alternatively in JSON form
tofu output -json
```

Great! Now we should see some information about our infrastructure. Lets open up the URL and ...

**UH OH**

The page didnt load did it? This is an important, but subtle lesson.

**Just because OpenTofu (or Terraform or ANY IaC tool) returns successfuly, doesn't mean that your infrastructure works the way you think it does.**

In this case the instance doesnt have access to get _out_ to the internet, so it can't download the yum packages or docker image.

This creates an opportunity to look at another OpenTofu command: `tofu taint` (stop laughing).

But first we need to give it access to the internet.

Make the following two changes:

In `main.tf` anywhere _inside_ your `aws_instance` block we need to reference our security group.

"What security group?" you might be asking. The one we're going to create in a few minutes. OpenTofu automatically handles infrastructure dependencies creating things in the correct order by creating a directed acyclic graph (DAG) of your resources when your 'reference' them. This allows you to put your infrastructure in any order in your files and break the files up so it works best for you without you having to worry about order of operations.

```hcl
  vpc_security_group_ids = [aws_security_group.this.id]
```

And add the security group that we'll use for this instance to `main.tf`. We're going to name it in code 'this'. AWS Security Groups can be rather complex so the naming really depends on how you intend to use it. Some people name them by protocol or by the service intended to use them.

```hcl
resource "aws_security_group" "this" {
  name = "my-security-group"
  description = "OpenTofu Foundations internet access for EC2 instance"

  # Allow HTTP traffic on IP address
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from anywhere (replace with a specific IP range for better security)
  }

  # Needs to be able to get to docker hub to download images
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }
}
```

Now, before we taint the resource, lets run tofu plan one more time.

```sh
tofu plan
```

You'll see something like:

```

OpenTofu will perform the following actions:

  # aws_instance.this will be updated in-place
  ~ resource "aws_instance" "this" {
      ~ vpc_security_group_ids               = [
          - "sg-aeb540a5",
        ] -> (known after apply)
        # omitted
    }

  # aws_security_group.this will be created
  + resource "aws_security_group" "this" {
    # omitted
    }

Plan: 1 to add, 1 to change, 0 to destroy.
```

It plans to add one resource (the security group) and change the instance. Let's apply it.

We'll use the `auto-approve` flag to skip the pesky prompt. This is very useful in CI ;)

```sh
tofu apply -auto-approve
```

We should see all of our changes, and if we access the site. Still nothing. Huh?

This is an AWS-ism, which is another important lesson. This instance is running, but the start up script failed the first time around. AWS doesn't re-evaluate the `user data`  on changes in EC2.

"Tainting" the instance will tell opentofu that we want to destroy it and recreate it. We'll taint it using the same 'address' we use to reference the resource in our code.

```sh
tofu taint aws_instance.this
tofu plan
```

You should see the following. OpenTofu will delete the instance, then make a new one. Treat those instances like cattle, baby!

```
Plan: 1 to add, 0 to change, 1 to destroy.
```

Wait a few moments for the instance to run through the user data commands, and you should be able to visit your nginx landing page!

---

### 3. Add a Variable for the Instance Name

Now as you scale IaC adoption across your org, being able to reuse a module will be important. There are many techniques for building reusuable, composable modules, but the first key is variables so that you can input different values into your config making it less 'static.'

**`variables.tf`**:

```hcl
variable "name_prefix" {
  type = string
}
```

**Note:** Good IaC design shouldn't overwhelm your developers that are using the module. Many modules that you find in the wild will have a variable to name _each_ resource. We all know naming is the hardest thing in computer science. We suggest having a single "name_prefix" variable so your user of the module can name their "instance" of the module and you as the operator can interpolate that into your resource names enforcing your conventions and making sure names are logical.

Add the `tags` attribute to the `aws_instance` resource. EC2 instances are "named" via tags, yes its weird.

```hcl
tags = {
  Name = var.name_prefix
}
```

Replace the `name` attribute of the `aws_security_group` to use the same name. I know we are going to have multiple security groups in this module, so I'll add a suffix using string interpolation to distinguish this one from the others we're going to create.

I'm going to suffix it as 'web-service' so we know why this is used when looking at it in the AWS console. A general bad practice IMO is naming security groups for the protocols in them versus how they are used. When you name them for protocols "allow-http" the name and the actual rules can start to diverge, and we know that the name is the identifier, so thats not great if we have to change it!

```hcl
  name = "${var.name_prefix}-web-service"
```

Re-run the plan & apply. You should be prompted for the instance name you want to use. Now, if the variable happens to change critical attributes of the resource, you may see that OpenTofu wants to destroy it. In this case you should see that the instance name can be updated in place, but the security group is _identified_ by its name, so AWS needs to create a new one to accomodate the change.

```bash
tofu plan
tofu apply -auto-approve
```
---

### 4. Using *.tfvars to provide variables (and reduce finger fatigue)

In my humble opinion, good tagging practices are key to good operations. We used tags a little bit above, but a unique feature of the AWS provider is the ability to set a default set of tags on all of your resources. We can do this by modifying the 'provider' block:

Update your AWS provider to the following (or set tags based on your company's conventions. You _do_ have tagging conventions, right? Right?!)

`provider.tf`:

```hcl
provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      environment = "dev"
      project     = "opentofu-foundations"
    }
  }
}
```



But before we update our resources, we know that we are going to get prompted for the name again. OpenTofu supports setting our variable names in config files and passing them into `tofu apply`

Create a file named `my.tfvars` and add the following to it:

```hcl
name_prefix = "PUT THE NAME YOU USED HERE"
```

Update your infrastructure and you should see two changes as tags are applied in place.

```sh
tofu apply -auto-approve -var-file my.tfvars
```

---

### 5. Add an AWS RDS Database Instance


Now, we will add an RDS instance for the database.

Add the following to `main.tf` or if you want to break up your code a bit, you could make `rds.tf` and add it there. We recommend keeping it all in `main.tf` until it starts to feel unwieldy. Remember, OpenTofu builds a DAG of your resources to handle dependencies, so you can put this block _anywhere_ in your *.tf files.

```hcl
resource "aws_db_instance" "this" {
  identifier        = var.name_prefix # cloud identifier for this database
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  engine            = "mariadb"
  engine_version    = "10.6"
  db_name           = "wordpress" # logical database name
  username          = "admin"
  password          = "yourpassword"
  skip_final_snapshot = true
}
```

```sh
tofu apply -auto-approve -var-file my.tfvars
```

You should see:

```
OpenTofu will perform the following actions:

  # aws_db_instance.this will be created
  + resource "aws_db_instance" "this" {
      + address                               = (known after apply)
  # omitted

  Plan: 1 to add, 0 to change, 0 to destroy.
  aws_db_instance.this: Creating...
  aws_db_instance.this: Still creating... [10s elapsed]
  aws_db_instance.this: Still creating... [20s elapsed]
```

This may take 10 minutes or so go get a coffee. #OpsLife

### 6. Replace Nginx instance with Wordpress (Object-type Variables & Interpolation)

To start up Wordpress we'll need to make a few changes.

Instead of hard coding the container image and tag, we're going to add another variable. OpenTofu supports a rich type system for variables.

We'll define the type as `object` and set the types of the keys. We'll also add a default and set it to wordpress since thats the use case for this module. Alternatively you can set the value in your `my.tfvars` file.

Add to `variables.tf`:

```hcl
variable "image" {
  type = object({
    name = string
    tag  = string
  })

  default = {
    name = "wordpress"
    tag  = "latest"
  }
}
```

Optional, add to `my.tfvars`:

```hcl
image = {
  name = "wordpress"
  tag = "latest"
}

Replace the contents of `user_data` with the following.

In this block we interpolate a few things:

1. the instances 'endpoint' that will be returned by the AWS API
2. the username, password, and db_name that we set on the instance
3. the image name and tag from our variables

```hcl
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user
              docker run -d \
                -e WORDPRESS_DB_HOST=${aws_db_instance.this.endpoint} \
                -e WORDPRESS_DB_USER=${aws_db_instance.this.username} \
                -e WORDPRESS_DB_PASSWORD=${aws_db_instance.this.password} \
                -e WORDPRESS_DB_NAME=${aws_db_instance.this.db_name} \
                -p 80:80 ${var.image.name}:${var.image.tag}
              EOF  
```

We need to add a security group to allow traffic to MariaDB:

Add the following to `main.tf`. Most people put the `data` block at the top.


```hcl
data "aws_vpc" "default" {
  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

resource "aws_security_group" "mariadb" {
  name        = "${var.name_prefix}-mariadb"
  description = "Allow access to MariaDB"

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"

    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }
}
```

Finally, we'll need to reference the security group on the database instance.

Add the following inside the `aws_db_instance` resource:

```hcl
  vpc_security_group_ids = [aws_security_group.mariadb.id]
```

Remember, in AWS user data won't be re-evaluated when it changes, so in this case we need to taint the resource to recreate it.

```hcl
tofu taint aws_instance.this
tofu apply -auto-approve -var-file my.tfvars
```

Wait about 2 minutes and open the URL and you should see a wordpress setup screen! Tada, your a devrel now!

If you've done a lot of copy/pasting so far and don't have an auto-formatter, then your code may look a little ugly. OpenTofu has a `fmt` command to auto format your code, lets run it before you commit your code.

```sh
tofu fmt
```

## Don't forget to TEAR IT ALL DOWN!!!

Don't forget to tear down your infrastructure so you don't burn up all those free credits!

```sh
tofu destroy
```

## Challenges

Want to keep hacking between now and week 2? Here are a few fun challenges to improve this module.

1. Configure AWS Secrets Manager ($1/secret/month after 30 days) or secure param store (10k free/account) to store db password and set up environment variables on the EC2 instances
2. Add an SSH rule and configure the instance to allow you to SSH in
3. Replace aws_instance.user_data with a launch template
4. Replace variables as the username and password with a `random_pet` username and a `random_string` password.

## Conclusion

In this first module, we walked through creating an EC2 instance, adding a MariaDB RDS instance, and setting up security groups. You also learned key Terraform/OpenTofu concepts like tainting resources, using variables, and planning/applying infrastructure changes.

* Data Resource: We learned how to use a data resource to read and use existing information from a provider, such as retrieving the default VPC.
* Resource: We explored defining resources, which are the building blocks of infrastructure, and how to configure them, such as EC2 instances and RDS databases.
* Provider: We configured a provider (AWS) to manage infrastructure in a specific region and apply global tags for consistency.
* Vars: Variables were introduced to make the configuration dynamic and reusable, such as setting instance names or toggling public database access.
* Output: We used output values to expose important information, like the instance's ARN or public URL, after the infrastructure is applied.
* `plan`, `taint`, `fmt`, `validate`, `apply`, `destroy`: We covered essential commands for managing infrastructure: plan to preview changes, taint to mark resources for recreation, apply to execute changes, init to initialize the configuration, fmt to format code, and destroy to tear it all down.
