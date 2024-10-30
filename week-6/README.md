# Week 6: Testing and Validation with OpenTofu

## Introduction

In this session we will learn about [OpenTofu's test](https://opentofu.org/docs/cli/commands/test/) CLI command as well as creating integration tests with [Terratest](https://terratest.gruntwork.io/docs/getting-started/quick-start/). The goal is to give you a strong foundation in both the features and testing philosophy.

In order to follow along you will need OpenTofu > 1.8.4 and Go installed on your system. The devcontainer has been updated with these dependencies.

## Why Test Terraform?

IaC provides operators with the ability to quickly spin up and spin down environments, enforce parity, and reuse common patterns via modules. Ensuring that your IaC behaves the way you expect and can be validated on every update protects users of your IaC and helps to insure unexpected issues do not arise.

## Tofu test

TofuTest is OpenTofu's built in testing tool. It runs OpenTofu and makes test assertions against either a plan or the state file of a run. The tool then gives a best effort attempt to clean up resources it has created. Cleanup of created resources should always be validated to avoid unexpected charges.

```bash
tofu test -h
Usage: tofu [global options] test [options]

  Executes automated integration tests against the current OpenTofu 
  configuration.

  OpenTofu will search for .tftest.hcl files within the current configuration 
  and testing directories. OpenTofu will then execute the testing run blocks 
  within any testing files in order, and verify conditional checks and 
  assertions against the created infrastructure. 

  This command creates real infrastructure and will attempt to clean up the
  testing infrastructure on completion. Monitor the output carefully to ensure
  this cleanup process is successful.

Options:

  -filter=testfile      If specified, OpenTofu will only execute the test files
                        specified by this flag. You can use this option multiple
                        times to execute more than one test file.

  -json                 If specified, machine readable output will be printed in
                        JSON format

  -no-color             If specified, output won't contain any color.

  -test-directory=path  Set the OpenTofu test directory, defaults to "tests". When set, the
                        test command will search for test files in the current directory and
                        in the one specified by the flag.

  -var 'foo=bar'        Set a value for one of the input variables in the root
                        module of the configuration. Use this option more than
                        once to set more than one variable.

  -var-file=filename    Load variable values from the given file, in addition
                        to the default files terraform.tfvars and *.auto.tfvars.
                        Use this option more than once to include more than one
                        variables file.

  -verbose              Print the plan or state for each test run block as it
                        executes.
```

### Directory Structure

The command supports either nested or flat layouts. In flat layouts your .tofutest.hcl files live next to your .tf or .tofu files

```
.
├── main.tf
├── main.tofutest.hcl
├── foo.tf
├── foo.tofutest.hcl
├── bar.tf
└── bar.tofutest.hcl
```

In nested layouts you have a dedicated test folder akin to common web frameworks

```
.
├── main.tf
├── foo.tf
├── bar.tf
└── tests
     ├── main.tofutest.hcl
     ├── foo.tofutest.hcl
     └── bar.tofutest.hcl
```

Lets setup some files and start testing!

```bash
mkdir tofutest 
cd tofutest 
touch main.tf
mkdir tests
cd tests
touch main.tofutest.hcl
cd ..
```

### Anatomy of a Test

```hcl
run "test_name" {
  command = plan/apply

  variables {
    name = "dave"
  }

  assert {
    condition     = file(local_file.test.filename) == "Hello world!"
    error_message = "Incorrect content in ${local_file.test.filename}."
  }
}
```

### Plan Tests

Plan tests are helpful when you need to validate that complex locals blocks or variable manipulation is occurring correctly. These test run very fast and provide a lot of confidence in complex locals.

```hcl
run "test_input_var_name_formatting" {
    command = plan

    variables {
        name = "   dave   "
    }

    assert {
        condition = local.name == "dave"
        error_message = "Expected name to not contain spaces"
    }
}
```

Let's now write the code to make this test pass

```hcl
variable name {
  type        = string
  default = ""
}

locals {
    name = var.name
}
```

Let's use a plan test to validate that a local block executes which will default our name variable to User if the name isn't present

```hcl
run "test_input_var_name_default" {
    command = plan
    assert {
        condition = local.name == "User"
        error_message = "Name is not defaulted"
    }
}
```

Now lets make the test pass

```hcl
locals {
    name = var.name == "" ? "User" : trimspace(var.name)
}
```

Testing counts and dynamic blocks can also be done using plan tests. Let's test that now

```hcl
run "test_no_pets" {
    command = plan
    assert {
        condition = random_pet.multiple == []
        error_message = "it created random pets when we it shouldnt have"
    }
}
```

```hcl
variable names {
  type        = list(string)
  default = [] 
}

resource random_pet "multiple" {
    count = length(var.names)
}
```

Because we have not passed in a variable and we are using the default we can see that no random_pets are created. Let's add the input variable to make some random pets

```hcl
run "test_multiple_random_pets" {
    command = plan
    variables {
        names = ["curly", "larry", "mo"]
    }
    assert {
        condition = length(random_pet.multiple) == 3
        error_message = "didn't create multiple pets"
    }
}
```

As we can see this test passes as well without any code changes.

### Apply tests

Plan tests can be very useful but not all aspects of OpenTofu code can be tested without actually running. Have you ever seen a plan with a value that is (known after apply)? This means an external resource will set that value after a run. An example of this might be a public IP for an instance, or an ID for a policy as it is set by the cloud itself. Apply tests use the state after the run to validate this information.

```hcl
run "test_pet_name_prefix" {
    command = apply
    variables  {
        names = ["curly"]
    }

    assert {
        condition = startswith(random_pet.multiple[0].id, "abcd_")
        error_message = "incorrect pet name prefix"
    }
}
```

```hcl
resource random_pet "multiple" {
    count = length(var.names)
    prefix = "abcd_"
}
```

If you try running the above test with the plan command, you will recieve an error as the ID is created during the run phase of OpenTofu execution. By swapping to apply the ID is set with our prefix.

### Mocking

New in OpenTofu 1.8.4 we can override providers, resources, and modules. Doing this allows for mocking outputs. This is very useful when you have a long running resource or a resource with side effects. AWS MSK for instance takes up to 45 minutes to run. You probably do not want your test suite to run that long.

#### Overriding a Resource

Let's setup and write a test first

```hcl
run "test_override" {
    command = apply

    assert {
        condition = data.local_file.main.content == "test"
        error_message = "local file content invalid"
    }
}
```

```hcl
data "local_file" "main" {
  filename = "file.txt"
}
```

```bash
touch file.txt
echo "hello world" >> file.txt
```

If we run this test it will fail. The content of our file in the data block is "hello world". To demonstrate mocking a resource we can add some test code to override that data block

```hcl
override_data {
    target = data.local_file.main
    values = {
        content = "test"
    }
}
```

#### Overriding Providers

Whole providers can be overwritten if you want, for instance, the AWS provider to return values without ever actually calling the AWS API you can achieve that by overriding the whole provider.

```hcl
mock_provider "local" {
    mock_data "local_file" {
        defaults = {
            content = "test"
        }
    }
}
```

Using tofu test gives you a very tight feedback loop when testing input validation and manipulation without any additional dependencies. Dynamic blocks and resources managed with iteration can be tested without actually running the HCL. Apply tests are slower but can validate that resources are actually created and look the way you are expecting. This can be useful for ensuring things like default values in the APIs are not unexpectly changing in ways that you are not prepared for.

The major flaw with tofu test is that it can not tell you if your infrastructure actually _works_. This would require a programming language to actually interact with your infrastructure in the cloud. This is where Terratest becomes useful.

## Terratest

Terratest is a set of Go modules which can be use in go's native testing library. The terraform module will run terraform, run your tests with retries, and then cleanup your infrastructure. There are many useful modules in the Terratest suite which can perform some common actions in various clouds and even technologies like Kubernetes and Docker

### Setting up Terratest

```bash
export AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxxxxxxxxxxx
export AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxx
mkdir terratest
cd terratest
touch main.tf
mkdir test
cd test
go mod init github.com/username/week-6
go mod tidy
touch main_test.go
go get github.com/aws/aws-sdk-go-v2/config
go get github.com/aws/aws-sdk-go-v2/config
go get github.com/aws/aws-sdk-go-v2/service/sns
go get github.com/aws/aws-sdk-go-v2/service/sqs
go get github.com/aws/aws-sdk-go/aws
go get github.com/gruntwork-io/terratest/modules/terraform
go get github.com/stretchr/testify/assert
```

```go
package test

import (
	"context"
	"encoding/json"
	"testing"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sns"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestSnsToSqs(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:    "../",
		TerraformBinary: "tofu",
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	want := "Hello World"
	snsArn := terraform.Output(t, terraformOptions, "sns_topic_arn")

	cfg, err := config.LoadDefaultConfig(context.Background(), config.WithRegion("us-west-2"))

	if err != nil {
		assert.Fail(t, err.Error())
	}

	snsClient := sns.NewFromConfig(cfg)

	_, err = snsClient.Publish(context.Background(), &sns.PublishInput{
		Message:  aws.String(want),
		TopicArn: aws.String(snsArn),
	})

	if err != nil {
		assert.Fail(t, err.Error())
	}

	sqsUrl := terraform.Output(t, terraformOptions, "sqs_queue_url")

	sqsClient := sqs.NewFromConfig(cfg)

	message, err := sqsClient.ReceiveMessage(context.Background(), &sqs.ReceiveMessageInput{
		QueueUrl: aws.String(sqsUrl),
	})

	if err != nil {
		assert.Fail(t, err.Error())
	}

	assert.Greater(t, len(message.Messages), 0)

	got := make(map[string]string)
	err = json.Unmarshal([]byte(*message.Messages[0].Body), &got)

	if err != nil {
		assert.Fail(t, err.Error())
	}

	assert.Equal(t, got["Message"], want)
}
```

```bash
cd test
go test -v -timeout 5m
```

In the above test we are:
- Initializing and applying our OpenTofu
- Once that has completed we are instructing our test to defer destruction of the created infrastructure until the test function as finished with the defer keyword
- Create an AWS config which will fetch credentials from our local env
- Get the sns topic arn from outputs
- Send a message using that arn to sns
- Get the SQS queue url from outputs
- Create an SQS client and check that we recieve at minimum 1 message
- Check the message for the expected content

Here is the code to make the test pass

```terraform
provider "aws" {
    region = "us-west-2"
}

resource "aws_sns_topic" "main" {
  name = "opentf-test"
}

resource "aws_sqs_queue" "main" {
  name       = "opentf-test"
}

resource "aws_sns_topic_subscription" "main" {
  endpoint  = aws_sqs_queue.main.arn 
  protocol  = "sqs"
  topic_arn = aws_sns_topic.main.arn
}

data "aws_iam_policy_document" "queue_policy" {
  statement {
    sid    = "Allow SNS to SendMessage to this queue"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.main.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.main.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id
  policy    = data.aws_iam_policy_document.queue_policy.json
}

output "sns_topic_arn" {
    value = aws_sns_topic.main.arn
}

output "sqs_queue_url" {
    value = aws_sqs_queue.main.id
}
```

As you can see, we have tested not only the existence but the connectivity of our cloud infrastructure. We have confirmed that group of resources which could resonably be grouped in a module for reuse is functional. However, this came at the cost of complexity. We added a new dependency (Go) and it required not just OpenTofu knowledge but knowledge of Go's testing package and the AWS sdk for go. These tests should be used very sparingly and likely should not be run in CI. These tests are more helpful before commiting code as they can be very long running.

## Challenges

1. Create a test/s using tofu test for a local which takes a list of numbers and filters numbers which are divisable by 3.
2. Create a test using tofu test which validates the correct number of ingresses are being created for the `aws_security_group` in the `aws_instance` module.  
3. Write a test with Terratest which calls the /wp_admin path in the `aws_instance` module and parses the HTML to validate the instance is serving WordPress