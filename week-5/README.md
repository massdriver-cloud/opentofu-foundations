# Week 5: Integrating OpenTofu into CI/CD Pipelines

## Introduction

In this session, we’ll integrate OpenTofu into CI/CD pipelines, automating infrastructure deployments. The goal is to set up a pipeline that tests, validates, and applies configurations, ensuring reliability and scalability. By the end, you’ll understand how to implement CI/CD for IaC workflows and the benefits it provides through automation.

Throughout this session we'll use the terms 'resource module' to refer to a reusuable component that isn't directly 'tofu apply'd and 'infrastructure module' to refer to modules that can and will be _applied_ directly. E.g.: aws_instance and aws_db_instance are _resource modules_ while your Wordpress code is an _infrastructure module_.

Prerequisites: 

* [Set up AWS Credentials with GitHub Actions](https://github.com/aws-actions/configure-aws-credentials) to automate linting, plan, and apply through PRs.
* (Optional) Configure the [Massdriver CLI](https://docs.massdriver.cloud/cli/overview) to collaborate, orchestrate, and document OpenTofu as diagrams through Massdriver (last 10m of session).

---

## What Benefits does IaC Provide?

We generally hear the following benefits we discussing IaC, but few are provided by IaC tools alone.

- ✅ Reproducibility: OpenTofu ensures reproducibility through code-based infrastructure definitions.
- ✅ Consistency: Provides consistent infrastructure by enforcing the same code across environments.
- ✅ Version control: VCS integration allows versioning of OpenTofu code
- ⚠️ Documentation: Partial; requires manual documentation or generation tools like terraform-docs, but excludes the overall cloud architecture
- ⚠️ Collaboration: Limited; best improved by integrating VCS and pull requests for code reviews.
- ⚠️ Audit trails: Requires integration with CI/CD or state backends.
- ⚠️ Rollbacks: Limited; Rollbacks can be performed through PR reverts.
- ❌ Change History: Needs VCS for tracking who changed the code, but no insight into what cloud resources were introduced across applies.
- ❌ Automation: Requires CI/CD pipelines to automate infrastructure deployments.
- ❌ Scalability: Scaling IaC adoption requires standardized, reusable templates and automation that abstract complexity, enabling teams to use IaC without deep infrastructure expertise.
- ❌ Security and compliance: Needs external tools like policy-as-code (e.g., OPA) for enforcing rules.
- ❌ Self-service: Requires integration with platforms like Massdriver or service catalogs for easy access.

But the truth is, most of the value of IaC isn't unlocked until you've integrated with CI/CD or an infrastructure automation platform.

---

## State Management

### What is State and Why Does It Matter?

State is the record of the current configuration of your infrastructure. It's a JSON format database of the resources managed by the module and their current configurations. Its "decentralized" in the worst sense of the word. If you don’t centralize it, you risk conflicting infrastructure changes and inconsistencies. We’ll set up a **remote state store** to prevent those problems.

HashiCorp has a great post on [why state is necessary](https://developer.hashicorp.com/terraform/language/state/purpose).

We'll deep-dive on state in the coming weeks, today we'll interface just enough to incorporate CI/CD.

There are many different backends for OpenTofu state, we're using AWS S3 for storage, and DynamoDB for locking. Beyond backends, there are a few strategies for how to organize your state storage.

#### Pros and Cons of Different Terraform State File Management Techniques

1. **One Bucket for All State**  
   - **Pros:** Simplifies management, easier backup, cost-efficient.
   - **Cons:** Increases security risk, harder to isolate projects, risk of state corruption, concurrency issues.

2. **Bucket for a Project**  
   - **Pros:** Better security and isolation, reduces concurrency problems, more organized structure for tracking.
   - **Cons:** Higher management overhead, potential complexity for shared resources across projects.

3. **Bucket Per Team**  
   - **Pros:** Isolation by team, easier access control, team accountability, reduces risk of errors between teams.
   - **Cons:** Inflexibility across multiple projects, potential duplication of effort, increased management.

4. **Bucket Per Environment**  
   - **Pros:** Environment isolation (dev, staging, prod), easier access control, clearer rollback/versioning.
   - **Cons:** Complexity increases with more environments, potential duplication of global/shared resources.

5. **Bucket Per App/Service**  
   - **Pros:** Fine-grained control, service-specific isolation, better troubleshooting at the service level.
   - **Cons:** High management overhead, complex when services share resources, bucket sprawl.

#### Create the module for managing state

For this workshop, we'll use a single state backend, in production, it really depends on your team size and devops maturity.

We've setup a [repo of shared modules](https://github.com/massdriver-modules/otf-shared-modules) to use as a part of this workshop session, you can either reference our module for state storage, or copy the contents of [`main.tf`](https://github.com/massdriver-modules/otf-shared-modules/blob/main/modules/opentofu_state_backend/main.tf) into `modules/opentofu_state_backend`. We'll be walking through the shared repo creation in the next few sections.


#### Create our state storage

First lets create a new infrastructure module (the modules we apply) to manage our state backend. Yes, we'll use IaC to define the bucket that other IaC modules use to store state.

```shell
mkdir -p infrastructure/my_state
touch infrastructure/my_state/main.tf
```

Paste the following into your main.tf file:

```terraform
variable "name_prefix" {
  description = "Name prefix for state-related resources"
  type        = string
}

module "state" {
  # Note: if you are managing your own shared modules, put your github url here
  source      = "github.com/massdriver-modules/otf-shared-modules//modules/opentofu_state_backend?ref=main"
  name_prefix = var.name_prefix
}

output "usage" {
  description = "Example state backend configuration"
  value       = module.state.usage
}
```

```shell
cd infrastructure/my_state
tofu init
tofu apply -var name_prefix="opentofu-foundations"
```

This will create two resources:

* dynamodb table for locking
* s3 bucket for state file storage

You should see output giving you a config to use in your `wordpress` module.

#### Migrate current state to that store

Deploy 'week-5/code/wordpress' first so you have state locally.

**Note:** The modules in `week-5` have been updated to use our shared modules, feel free to change the `source` attributes to your own GitHub URL.

```shell
tofu init -upgrade # the modules directory may have moved depending on how you are coming from week-4
tofu apply
```

Let's take a _quick_ peek at our statefile.

```shell
cat terraform.tfstate | jq .
cat terraform.tfstate | jq 'keys'
```

You can see our resources, data blocks, outputs, and much more.

Now we can take the state configuration that was output from creating our state and add it to our code.

We'll take the `backend` block and paste it inside the `terraform` block in `main.tf`:

```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.68"
    }
  }

  backend "s3" {
    bucket         = "opentofu-foundations-opentofu-state-yc5m" # your bucket name here
    key            = "wordpress/terraform.tfstate" # Change the path per infrastructure module
    dynamodb_table = "opentofu-foundations-opentofu-locks-yc5m" # your bucket name here
    region         = "us-west-2" # your region here
  }
}
```

**Alternatively** state can be set during init w/ env vars.

```shell
terraform init \
  -backend-config="bucket=$S3_BUCKET_NAME" \
  -backend-config="key=module1/terraform.tfstate" \
  -backend-config="dynamodb_table=$DYNAMODB_TABLE" \
  -backend-config="region=us-west-2"
```

Now we'll _migrate_ our state:

```shell
tofu init -migrate-state
```

Did it work?

```shell
mv terraform.tfstate terraform.tfstate.old
tofu plan
```

If you got a plan that wasn't a net new create, it worked!

---

## Code Organization

### Code Organization and Scaling Infrastructure

Your code organization impacts how easily you scale infrastructure-as-code adoption. Here are some common approaches:

#### 1. **Mono Repo (All Modules and Services in One Repo)**
   - **Pros**: Simple, single version control, consistent codebase, easier to enforce standards across services.
   - **Cons**: Difficult to scale, tightly coupled code and services, CI bottlenecks as all services share the same pipeline.
   
   **Best for**: Small teams or projects that don’t anticipate large-scale growth, where tight integration between services is desirable.

#### 2. **1+N Repos (Central Module Repo + Service Repos)**
   - **Pros**: Modular, shared reusable modules across services, decentralized service development allowing independent work.
   - **Cons**: Versioning issues with shared modules, dependency management complexities, more complex CI setup to handle changes across repos.
   
   **Best for**: Teams needing some code sharing but who also want to decouple service development, particularly where reusability of modules is important.

#### 3. **M+N Repos (Separate Module and Service Repos)**
   - **Pros**: High modularity, granular versioning per module and service, clear ownership of repos, promotes independent scaling of services.
   - **Cons**: Increased overhead to manage multiple repos, coordination challenges when updating shared modules, complex dependency management.
   
   **Best for**: Larger teams or organizations that need strict modularity and granular control over both services and modules, and have the resources to handle the overhead.

We are going to use a central shared repo of modules, and a repo per app/service. This will give us a realistic maintenance feel while not overwhelming us with a repo per shared module. We'd already have 3!

Create a new github repo, we'll call ours [`otf-shared-modules`](https://github.com/massdriver-modules/otf-shared-modules/tree/main) and move your shared modules Week 4 shared modules there. If you've modified your week 4, feel free to copy ours to your repo.

```shell
cp -R week-4/code/modules path/to/your/git/repo/modules
```

---

## OpenTofu GitHub Actions

There are two main CI/CD workflows we are going to set up:

* Formatting and validation on our shared 'resource' modules like `tofu fmt` and `tofu validate` to make sure shared code is valid and formatted.
* Infrastructure lifecycle management and costs on our 'infrastructure' modules.

This isn't a workshop on all of the tools you can toss in your CI/CD pipeline or it'd be a 400 week workshop. Besides the few tools we are going to integrate, other common tools to include are:

* Shared 'resource' modules: tflint, terraform-docs, terratest for common use cases
* Application / Service infrastructure modules: OPA, Checkov, Infracost

### Configuring shared resource modules GitHub Actions

My general recommendation when adopting a VCS-based infrastructure automation is to _lean hard_ into reusable GitHub Actions. If we were going to be making a git repo **per** shared module, it can create a significant amount of maintenance work to make changes like updating the version of OpenTofu, or changing how you fmt / validate.

Luckly for this session, we picked a monorepo approach to our shared modules, so we'll just have one GitHub Action workflow to run.

This action will run `tofu fmt` and `tofu validate` on any module that changed in the pull request. This will help make sure you have consistent formatting of your OpenTofu HCL code and that the modules are _valid and executable_, which doesn't necessarily mean the do what you want :D

There are a whole host of other tools like `tflint`

Add the following to `.github/workflows/opentofu-validate.yml` in your **shared modules repo**:

```yaml
name: OpenTofu Validate

on:
  pull_request:
    branches:
      - main

jobs:
  changed_files:
    runs-on: ubuntu-latest
    name: Test changed-files
    steps:
      - uses: actions/checkout@v4
      
      - uses: opentofu/setup-opentofu@v1
      
      - name: Get changed files
        id: changed-files
        uses: tj-actions/changed-files@v45
        with:
          files: "./modules/**"
          dir_names: "true"

      - name: Validate OpenTofu modules
        if: steps.changed-files.outputs.any_changed == 'true'
        run: |
          for dir in ${{ steps.changed-files.outputs.all_changed_files }}; do
            echo "Validating: $dir"
            cd $dir
            tofu init
            tofu fmt -check
            tofu validate
            cd -
          done
```

Here is an example workflow [run](https://github.com/massdriver-modules/otf-shared-modules/actions/runs/11470136519/job/31918736046#step:6:1).

### Configuring our Wordpress infrastructure module

**Note:** You'll need to set up your AWS Credentials in GitHub. For production you'll want to use [AWS IAM Roles](https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/) and official [AWS GH Actions](https://github.com/aws-actions/configure-aws-credentials), but for a workshop something as simple as key/value may be fine.


Instead of creating a new github repo, we'll use this one and scope our CI/CD actions to week-5 in `.github/workflows/week-5.yml`.

Here is the bulk of the workflow for planning. See the `.github` directory for the full config including PR commenting.

```yaml
name: Week 5

on:
  pull_request:
    paths:
      - 'week-5/code/wordpress/**'

jobs:
  opentofu-plan:
    runs-on: ubuntu-latest
    env:
      TF_IN_AUTOMATION: true
      TF_INPUT: false
    defaults:
      run:
        working-directory: week-5/code/wordpress
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2

      - name: Setup OpenTofu
        uses: opentofu/setup-opentofu@v1

      - name: OpenTofu fmt
        id: fmt
        run: tofu fmt -check
        continue-on-error: true        

      - name: OpenTofu init
        id: init
        run: |
          tofu init \
            -backend-config="bucket=opentofu-foundations-opentofu-state-yc5m" \
            -backend-config="dynamodb_table=opentofu-foundations-opentofu-locks-yc5m" \
            -backend-config="region=us-west-2" \
            -backend-config="key=wordpress/terraform.tfstate"

      - name: OpenTofu validate
        id: validate
        run: tofu validate -no-color

      - name: OpenTofu plan
        id: plan
        run: tofu plan -no-color
        continue-on-error: true
```

Before we commit our code, we're also going to need to include our `tfvars` to apply our variables to our config. We're going to get into managing tfvars with workspaces in a few sessions, for now we'll just add our tfvars as an **autoloaded* tfvars file. If you have `.gitignore` you may have to force add to git.

```shell
# feel free to set your own name or if you already have a tfvars file rename it
echo 'name_prefix="otf-wk5-YOUR_NAME" > default.auto.tfvars
git add default.auto.tfvars -f
```

Open up a pull request to your repo and you should see a workflow run and your plan added to the PR as a comment!

Here is an example PR plan [comment.](https://github.com/massdriver-cloud/opentofu-foundations/pull/6#issuecomment-2430899531)

Woohoo, this is a good start, but as noted above, its important to add workflow actions for security, compliance, costs, and other organizational policies.

Benefits of IaC + CI/CD

- ✅ Reproducibility: OpenTofu ensures reproducibility through code-based infrastructure definitions.
- ✅ Consistency: Provides consistent infrastructure by enforcing the same code across environments.
- ✅ Version control: VCS integration allows versioning of OpenTofu code
- ⚠️ Documentation: Partial; requires manual documentation or generation tools like terraform-docs, but excludes the overall cloud architecture
- ✅ Collaboration: Integration with PR workflows to run and share plans for approval
- ✅ Audit trails: Merged PRs act as audit trail. _Can be difficult to navigate across many git repos or infrastructure modules in the same repos as an active codebase._
- ✅ Rollbacks: Rollbacks can be performed through PR reverts. _Can be difficult to navigate across many git repos or infrastructure modules in the same repos as an active codebase._
- ✅ Change History: VCS for what changed, but no insight into what cloud resources were introduced across applies.
- ✅ Automation: CI/CD pipelines to automate infrastructure deployments.
- ⚠️ Scalability: Code repo organization provides a baseline for adoption, but module discovery and workspace management are cumbersome.
- ⚠️ Security and compliance: Needs external tools like policy-as-code (e.g., OPA) for enforcing rules, but can easily be incorporated into CI workflows. Maintenance burden of CI workflows can increase significantly.
- ❌ Self-service: Requires integration with platforms like Massdriver or service catalogs for easy access.

---

**Remember to teardown your resources!!!***

## Challenges

1. When you created the state store, _its_ state is stored locally. Migrate your state storage bucket and table to use its own bucket for state storage.
2. Add a GitHub Action to apply your configuration. Should it be applied before or after merging into main?
3. Integrate terraform-docs to update your readme either as a github action or a pre-commit.
