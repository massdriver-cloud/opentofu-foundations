# OpenTofu Foundations Workshop Series

[Register Here](https://www.massdriver.cloud/blogs/opentofu-foundations---a-free-weekly-workshop-to-build-your-iac-skills)

Welcome to the **OpenTofu Foundations Workshop**! This repository contains the materials and resources for a 10-week, hands-on workshop series designed to help you build and enhance your skills in Infrastructure as Code (IaC) using **OpenTofu**.

## Overview

The **OpenTofu Foundations Workshop** is a free, 10-week series where we guide participants through the process of becoming confident OpenTofu practitioners. Each week focuses on a key aspect of OpenTofu, covering everything from the basics of IaC to advanced infrastructure management and scaling.

The goal is to provide a practical, hands-on learning experience, allowing you to apply the skills you acquire directly to real-world infrastructure projects.

## Workshop Structure

This series is designed to build your knowledge incrementally. Each session focuses on a specific topic, and by the end of the series, you’ll have a comprehensive understanding of how to manage, scale, and automate infrastructure with OpenTofu.

### Workshop Schedule

#### Week 1: Getting Started with OpenTofu - 2024-09-25 @ 10A PST / 5P GMT

Introduction to OpenTofu, its purpose, and basic installation. Learn to set up a project and understand the foundational concepts of Infrastructure as Code. Write your first OpenTofu configuration and define basic infrastructure resources like compute instances and networking components.

#### Week 2: Modular Infrastructure with OpenTofu - 2024-10-02 @ 10A PST / 5P GMT

Organize your code with reusable modules. Learn how to import modules into configurations and apply best practices for modular infrastructure design.

#### Week 3: Functions and Control Structures in OpenTofu - 2024-10-09 @ 10A PST / 5P GMT

Learn to enhance your infrastructure configurations using OpenTofu’s built-in and custom functions, and control structures. This session will cover how to use functions and control structures like conditionals and loops to create dynamic and adaptable configurations. We'll also dive into creating custom functions using `opentofu/terraform-provider-go` to extend the functionality of your setups.

#### Week 4: Advanced OpenTofu Resource Management - 2024-10-16 @ 10A PST / 5P GMT

Explore advanced resource configurations using locals, outputs, blocks, dynamic blocks, and dependencies. Create more dynamic and flexible infrastructure setups.

#### Week 5: Integrating OpenTofu into CI/CD Pipelines - 2024-10-23 @ 10A PST / 5P GMT

Integrate OpenTofu into CI/CD pipelines to automate infrastructure deployments. Set up a pipeline to test, validate, and apply configurations reliably.

#### Week 6: Testing and Validation with OpenTofu - 2024-10-30 @ 10A PST / 5P GMT

Learn how to incorporate testing and validation into your OpenTofu workflows. This session will focus on tools and practices for testing your infrastructure code, including syntax validation, resource policy checks, and simulating infrastructure changes before applying them. By the end of this week, you'll know how to ensure that your configurations are reliable, secure, and ready for production.

#### Week 7: Multi-Environment Infrastructure Management - 2024-11-06 @ 10A PST / 5P GMT

Manage and deploy infrastructure across multiple environments. Set up configurations for development, staging, and production to ensure consistency.

#### Week 8: Understanding State Management - 2024-11-13 @ 10A PST / 5P GMT

Explore how OpenTofu manages the state of your infrastructure. Learn about state files, secure storage, and state locking strategies for managing multiple environments.

#### Week 9: Mastering State Management and Resource Imports - 2024-11-20 @ 10A PST / 5P GMT

Deep dive into state management, reading remote state, including importing existing infrastructure and handling state changes. Learn best practices for managing legacy resources.

#### Week 10: Scaling and Best Practices for OpenTofu - 2024-11-27 @ 10A PST / 5P GMT

Focus on scaling OpenTofu for large infrastructures and adopt best practices. Organize large projects, manage team collaboration, and implement advanced infrastructure strategies.

### Prerequisites

* An AWS Account - Register [here](https://aws.amazon.com/free/), everything we'll build is on the AWS Free Tier
* OpenTofu CLI - Download [here](https://opentofu.org/docs/intro/install/)
* Download the AWS CLI ([here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)) and setup your AWS credentials - Docs [here](https://docs.aws.amazon.com/cli/v1/userguide/cli-configure-files.html)
* (Optional) A Massdriver Account - Get a free one-year trial [here](https://app.massdriver.cloud/register?attribution=OpenTofu)

Find an AWS Linux Machine Image (AMI) for your region:

```shell
aws ec2 describe-images \
    --filters \
        "Name=owner-alias,Values=amazon" \
        "Name=platform-details,Values=Linux/UNIX" \
        "Name=name,Values=amzn2-ami-hvm-2.*-x86_64-gp2" \
    --query 'Images[*].[Name,ImageId]' \
    --output text \
    --region YOUR_REGION_HERE
```

## Who is This Workshop For?

- **Beginners**: If you're new to Infrastructure as Code, this series will help you build a strong foundation in OpenTofu.
- **Intermediate Users**: If you're familiar with other IaC tools, this workshop will help you apply those skills using OpenTofu’s capabilities.
- **Advanced Users**: This series will deepen your knowledge of advanced topics like state management, resource imports, and scaling infrastructure.

## How to Use This Repository

Each week, resources such as example configurations, supporting documentation, and notes will be uploaded here. You can follow along with the workshop by:
1. Cloning the repo.
2. Following the instructions provided for each week’s session.
3. Experimenting with the example configurations and trying out the exercises.
