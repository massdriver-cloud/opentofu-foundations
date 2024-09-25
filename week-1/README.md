# Week 1 Course: Introduction to OpenTofu and Basic Commands

**Duration:** 1 hour


## Introduction

Welcome to week one of the OpenTofu workshop! In this module, you'll learn how to create an EC2 instance running NGINX, set up a MariaDB database, and configure basic infrastructure in AWS. We’ll go through creating instances, security groups, and databases while discussing key Terraform/OpenTofu concepts.

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

`tofu init`
`tofu fmt`
`tofu validate`
`tofu plan`
`tofu apply`

## Walkthrough

WALKTHROUGH WILL BE UPLOADED AFTER THE SESSION.

## Challenges

Want to keep hacking between now and week 2? Here are a few fun challenges to improve this module.

1. Configure AWS Secrets Manager to store db password and set up environment variables on the EC2 instances (Free Tier: 30 days from creating your first secret)
2. Add an SSH rule and configure the instance to allow you to SSH in
3. Replace aws_instance.user_data with a launch template

## Conclusion

In this first module, we walked through creating an EC2 instance, adding a MariaDB RDS instance, and setting up security groups. You also learned key Terraform/OpenTofu concepts like tainting resources, using variables, and planning/applying infrastructure changes.

* Data Resource: We learned how to use a data resource to read and use existing information from a provider, such as retrieving the default VPC.
* Resource: We explored defining resources, which are the building blocks of infrastructure, and how to configure them, such as EC2 instances and RDS databases.
* Provider: We configured a provider (AWS) to manage infrastructure in a specific region and apply global tags for consistency.
* Vars: Variables were introduced to make the configuration dynamic and reusable, such as setting instance names or toggling public database access.
* Output: We used output values to expose important information, like the instance's ARN or public URL, after the infrastructure is applied.
* `plan`, `taint`, `fmt`, `validate`, `apply`, `destroy`: We covered essential commands for managing infrastructure: plan to preview changes, taint to mark resources for recreation, apply to execute changes, init to initialize the configuration, fmt to format code, and destroy to tear it all down.
