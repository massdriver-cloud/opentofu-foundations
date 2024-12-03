# Week 10: Tooling and Best Practices in OpenTofu

## **Introduction**

This week, we’ll focus on essential tools that ensure your OpenTofu configurations are reliable, secure, and maintainable. By the end of this session, you’ll have enabled key tools, understood their value, and integrated them into your workflow.

---

## **1. Setting up Pre-commit Hooks**

Pre-commit hooks run checks automatically before code is committed, saving time and reducing errors.

While they're a great tool for ensuring quality before committing to git, they're also a great way to learn these tools without waiting for CI. :D

### **Setup Pre-commit**
Install pre-commit and initialize the hooks:
```bash
pip install pre-commit
pre-commit install
```

Add `.pre-commit-config.yaml` to your repo root:
```yaml
repos:
  - repo: https://github.com/tofuutils/pre-commit-opentofu
    rev: v2.1.0
    hooks:
      - id: tofu_fmt
      - id: tofu_validate
      - id: tofu_tflint
      - id: tofu_docs
      - id: tofu_providers_lock
      - id: tofu_checkov
      - id: infracost_breakdown
```

**Aside:** If you want to limit these to running for just week 10 see the configuration in [.pre-commit-config.yaml](.pre-commit-config.yaml).

Run the hooks manually:
```bash
pre-commit run --all-files
```

---

## **2. A Tour of OpenTofu Tooling**

### **2.1 Tofu Format (`tofu_fmt`)**

#### What It Does
- Aligns code blocks for consistent indentation and spacing.
- Ensures your code adheres to OpenTofu's style guidelines.

#### Exercise
Run the formatter on a module:
```bash
pre-commit run tofu_fmt --all-files
```

- Look at any changes made to your `.tf` files.
- Add unaligned code and rerun to see it corrected.

#### Tips & Best Practices
- Run `tofu_fmt` before committing changes to catch style issues early.
- Use `tofu fmt -check` in CI pipelines to enforce formatting.

---

### **2.2 Tofu Validate (`tofu_validate`)**

#### Contextual Setup
Validation ensures that your configuration files are syntactically correct and ready for deployment.

#### What It Does
- Catches syntax errors in `.tf` files.
- Validates that all required inputs are defined.

#### Exercise
Run validation on your module:
```bash
pre-commit run tofu_validate --all-files
```

Try intentionally breaking syntax (e.g., delete a closing brace) and see the error it produces.

#### Tips & Best Practices
- Always run `tofu_validate` after adding new resources or variables.
- Use in conjunction with `tofu plan` to catch logical errors.

---

### **2.3 TFLint (`tofu_tflint`)**

#### Contextual Setup
TFLint is a framework and each feature is provided by plugins, catching common misconfigurations.

#### What It Does

- Find possible errors (like invalid instance types) for Major Cloud providers (AWS/Azure/GCP).
- Warn about deprecated syntax, unused declarations.
- Enforce best practices, naming conventions.

#### Exercise

Add a `.tflint.hcl` config file:

```hcl
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
```

Introduce an invalid instance type:
```hcl
variable "instance_type" {
  default = "t1.micro"  # Invalid
}
```

Run the linter:
```bash
pre-commit run tofu_tflint --all-files
```

Fix the error by switching to `t3.micro` and rerun.

#### Tips & Best Practices

- Update TFLint plugins regularly to stay current with your cloud provider.
- Customize rules for organizational policies, like enforcing specific tags.

---

### **2.4 Module Documentation (`tofu_docs`)**

Automatically generated documentation reduces manual work and ensures your modules are well-documented.

#### What It Does
- Updates your `README.md` with all inputs, resources, providers, modoules, and outputs.
- Ensures documentation is always up to date.

#### Exercise

Add fences to your README.md for tofu_docs to add documentation to:

```md
<!-- BEGINNING OF PRE-COMMIT-OPENTOFU DOCS HOOK -->
<!-- END OF PRE-COMMIT-OPENTOFU DOCS HOOK -->
```

Add a description to an input variable:
```hcl
variable "instance_type" {
  description = "The type of EC2 instance to launch."
  default = "t3.micro"
}
```

Run:
```bash
pre-commit run tofu_docs --all-files
```

Check the updated `README.md`.

#### Tips & Best Practices

- Use detailed descriptions for inputs and outputs to improve module usability.
- Generate docs after every significant change to the module.

---

### **2.5 Provider Version Locking (`tofu_providers_lock`)**

Locking provider versions ensures reproducible builds and prevents breaking changes from updates.

#### What It Does
- Locks provider versions in `.terraform.lock.hcl`.
- Ensures your team uses consistent provider versions.

#### Exercise
Run the provider lock tool:
```bash
pre-commit run tofu_providers_lock --all-files
```

Inspect the `.terraform.lock.hcl` file and note the locked versions.

#### Tips & Best Practices
- Use version ranges like `~> 3.0` for flexibility within a major version.
- Update locks periodically to stay secure and compatible.

---

### **2.6 Checkov (`tofu_checkov`)**

Checkov scans your configuration for security misconfigurations, ensuring compliance with best practices.

#### Checkov v. Trivy v. Terrascan

These tools aren't mutually exclusive, but their value becomes clearer as your organization grows and faces new challenges. Checkov is often the first step—easy to integrate, great for catching Terraform misconfigurations, and enforcing compliance. But as your infrastructure scales and your security needs become more complex, you’ll start reaching for Terrascan for custom policies or Trivy to tackle vulnerabilities in container images, dependencies, and other assets beyond Terraform.

The overlap between these tools isn’t a bad thing—it reflects the natural progression of security as organizations mature. You might start with Checkov because it’s lightweight and effective, then bring in Terrascan when you need policy flexibility or Trivy when your stack grows into containers and runtime environments. It’s not about picking the perfect tool, but about layering the right ones as your needs expand. Start small, scale smart.

### **Comparison Table**

| Feature                     | **Terrascan**                       | **Trivy**                          | **Checkov**                        |
|-----------------------------|--------------------------------------|-------------------------------------|-------------------------------------|
| **Primary Focus**           | IaC security and policy enforcement | Container, IaC, and runtime security | IaC security and compliance        |
| **Languages/Files Supported**| Terraform, Kubernetes, Helm, CloudFormation | Container images, IaC, file systems, runtime environments | Terraform, Kubernetes, CloudFormation |
| **Vulnerability Scanning**  | No                                  | Yes                                 | No                                  |
| **Compliance Standards**    | Yes (OPA extensible)                | Yes                                 | Yes                                 |
| **Runtime Environment Scan**| No                                  | Yes (e.g., Kubernetes clusters)    | No                                  |
| **Policy Extensibility**    | OPA policies                        | Limited                             | Custom rules in YAML               |
| **SBOM Generation**         | No                                  | Yes                                 | No                                  |

**Checkov** is your go-to for quick, powerful checks that catch Terraform misconfigurations and ensure compliance. It's simple to set up, integrates nicely into CI/CD pipelines, and provides a solid foundation for any Terraform-heavy workflow. 

**Terrascan** steps in when you need more customization. With its Open Policy Agent (OPA) backend, you can write highly specific policies that align with your organization's needs. 

**Trivy**, on the other hand, is the multitool—it does Terraform misconfig checks but shines when you need to scan container images, runtime environments, or dependencies alongside your infrastructure.


#### What It Does
- Flags issues like open security groups or unencrypted storage.
- Checks compliance against frameworks like SOC2 or NIST.

#### Exercise
Run Checkov on a module:
```bash
pre-commit run tofu_checkov --all-files
```

Example warning:
```
CKV_AWS_20: "Ensure S3 buckets are not public"
File: main.tf:12-19
Resource: aws_s3_bucket.public_bucket
```

Fix the issue and rerun.

#### Tips & Best Practices
- Focus on critical issues to improve security posture incrementally.
- Use Checkov in CI to prevent insecure code from being deployed.

---

### **2.7 Infracost (`infracost_breakdown`)**

#### Contextual Setup
Infracost estimates the cost of your infrastructure, enabling cost-conscious decisions.

#### What It Does
- Provides cost breakdowns for your resources.
- Helps identify expensive configurations before deployment.

#### Exercise
Run Infracost:
```bash
pre-commit run infracost_breakdown --all-files
```

Check the output and identify the most expensive resource.

#### Tips & Best Practices
- Use Infracost during pull requests to enforce cost-awareness.
- Share breakdowns with stakeholders to justify infrastructure costs.

---

## **Challenges**

1. Run `tofu_docs` and update a variable description.
2. Configure `tofu_tflint` and correct any detected issues.
3. Run `tofu_checkov` and fix or silence errors.

**Happy coding!** 🎉
