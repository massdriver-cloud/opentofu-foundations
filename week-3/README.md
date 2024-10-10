# Week 3 Course: Functions and Control Structures with OpenTofu

**Duration:** 45 minutes

## Introduction

Welcome to week three of the [OpenTofu workshop](https://www.massdriver.cloud/blogs/opentofu-foundations---a-free-weekly-workshop-to-build-your-iac-skills)! This week, we'll dive into functions and control structures. 90% of what we do as programmers is validate unknown data being passed to our programs, and manipulating imperfect data so we can connect software modules together. Functions help us provide a better more intuitive user experience and keep our code clean.

## Course Objectives

- Introduction to the OpenTofu console.
- Understand OpenTofu's primitive data types.
- Understand how functions are used to manipulate those types.
- Undestanding of ternary operators and how they are used in OpenTofu.
- Understanding of iteration and how it helps us manipulate data.
- Brief introduction to the go provider.

## Walkthrough

### 1. Types

Like most programming paradigms HCL (the language that powers OpenTofu), has core types which allow us to pass information to and around our program. The basic types in HCL are:

- **boolean**
  -  A binary value which represents true or false
- **number**
  - A value which represents a whole number _or_ a decimal. Ex. 10, 3.14
- **string**
  - A collection of characters which represent text. Under the hood this is a collection of 1s and 0s but together the string type forms text that is useful to another system. Ex. "Hello, World!", "arn:aws:iam::123456789012:user/johndoe"
- **null**
  - Represents the absence of a value. If you had a basket of 5 apples and asked for the 6th largest apple, give it does not exist it would be null.
- **set**
  - A collection of data of the same type which has no order or secondary identifiers for values. Ex. ["foo", "bar", "baz"].
- **list**
  - A collection of data which is ordered and is identified by incrementing whole numbers starting at 0. Ex. ["hello", null, true].
- **map/object**
  - A collection of data which is unordered but has a unique key which is the secondary identifier. Ex. {"name" = "dave", "occupation" = "engineer"}


For the rest of the demo, we will use an OpenTofu console

```bash
tofu console
```

### 2. Operators

Operators are special functions which perform an action on exactly two values on either side of the operator.

- **[math](https://developer.hashicorp.com/terraform/language/expressions/operators#arithmetic-operators)**
  - Simple arithmetic like addition, subtraction and multiplication
- **[equality](https://developer.hashicorp.com/terraform/language/expressions/operators#equality-operators)**
  - Checks if two values are equal or not equal
- **[comparison](https://developer.hashicorp.com/terraform/language/expressions/operators#comparison-operators)**
  - Evaluates the relative relationship between two values like greater than or less than
- **[logic](https://developer.hashicorp.com/terraform/language/expressions/operators#logical-operators)**
  - Evaluation of boolean logic with AND, OR, and NOT

### 3. Functions

[Functions](https://developer.hashicorp.com/terraform/language/functions) are small pieces of code that take in one or more arguments and produce a value. Functions are made to encapsulate common manual tasks.

- [split](https://developer.hashicorp.com/terraform/language/functions/split)
  ```hcl
  > split(",", "foo,bar,baz")
  ["foo", "bar", "baz"]
  ```
- [join](https://developer.hashicorp.com/terraform/language/functions/join)
  ```hcl
  > join(",", ["foo", "bar", "baz"])
  "foo,bar,baz"
  ```
- [replace](https://developer.hashicorp.com/terraform/language/functions/replace)
  ```hcl
  > replace("1 + 2 + 3", "+", "-")
  "1 - 2 - 3"
  ```
- [trim](https://developer.hashicorp.com/terraform/language/functions/trim)
  ```hcl
  > trim("   hello   ", "")
  "hello"
  ```
- [parseint](https://developer.hashicorp.com/terraform/language/functions/parseint)
  ```hcl
  > parseint("100", 10)
  100
  ``` 
- [coalesce](https://developer.hashicorp.com/terraform/language/functions/coalesce)
  ```hcl
  > coalesce("a", "b")
  "a"
  > coalesce("", "b")
  "b"
  ```
- [compact](https://developer.hashicorp.com/terraform/language/functions/compact)
  ```hcl
  > compact(["a", "", "b", null, "c"])
  ["a", "b", "c"]
  ```
- [distinct](https://developer.hashicorp.com/terraform/language/functions/distinct)
  ```hcl
  > distinct(["a", "b", "a", "c", "d", "b"])
  ["a", "b", "c", "d"]
  ```
- [jsonencode](https://developer.hashicorp.com/terraform/language/functions/jsonencode)
  ```hcl
  > jsonencode({"hello"="world"})
  {"hello":"world"}
  ```
- length
  ```hcl
  > length("hello")
  5
  > length(["a", "b"])
  2
  ```
- [tostring](https://developer.hashicorp.com/terraform/language/functions/tostring)
  ```hcl
  tostring(1)
  "1"
  ```
- [try](https://developer.hashicorp.com/terraform/language/functions/try)
  ```hcl
  > try(["foo", "bar"][0], "fallback")
  "foo"
  > try(["foo", "bar"][3], "fallback")
  "fallback"
  ```

### 4. If and Ternary Expressions
Control structures allow you to execute code in the event that a condition (or case) is either true or false. The main control structure is a ternary expression

```hcl
> true ? "hello" : "world"
"hello"
> false ? "hello" : "world"
"world"
```

There is another control stucture used in comprhensions. The if keyword returns a value if the case is true.

```hcl
> var.list = ["a", "", "c"]
> [for s in var.list : upper(s) if s != ""]
["A", "C"]
```

### 5. Comprehensions

Comprehensions are expressions which allow you to iterate over a list or a set and manipulate the data to create a new list or map.

```hcl
> var.list = ["a", "", "c"]
> [for s in var.list : upper(s) if s != ""]
["A", "C"]
```

```hcl
> var.list = ["a", "", "c"]
> {for s in var.list : upper(s) => s }
{"A" = "a", "C" = "c"}
```

### 6. Making Your Own Functions With Go

In the event the built in functions don't work for you, there is likely a provider which will enable you to do what you need to do. Providers are maintained opensource and they vary from basic JQ operations to ordering a pizza from Dominos. However, if you need a small piece of functionality that doesnt exist and want to make your own functions you can use the [OpenTofu go provider](https://github.com/opentofu/terraform-provider-go)

##### **`providers.tf`**
```hcl
terraform {
    required_providers {
        go = {
            source  = "registry.opentofu.org/opentofu/go"
            version = "0.0.1"
        }
    }
}
```

##### **`main.tf`**

```hcl
provider "go" {
    go = file("./lib.go")
}

locals {
    // Note: Function name is all lowercase. No camel casing here.
    record = provider::go::exchangerate({
        currencies = "Canada-Dollar"
    })
    user_data = <<-EOF
                #!/bin/bash
                yum update -y
                amazon-linux-extras install docker -y
                service docker start
                usermod -a -G docker ec2-user
                docker run -d \
                  -e WORDPRESS_DB_HOST=xxxxxxxxxxx \
                  -e WORDPRESS_DB_USER=xxxxxxxxxxxx \
                  -e WORDPRESS_DB_PASSWORD=xxxxxxxxxxxxxxx \
                  -e WORDPRESS_DB_NAME=xxxxxxxxxxxxxxx \
                  -p 80:80 xxxxxxxxxxxx:xxxxxxxxxxxx
              EOF
    exchange_rate_env_string = "  -e CAD_EXCHANGE_RATE=${local.record.exchangeRate} \\"
    split_user_data = split("\n", tostring(local.user_data))
    parsed_user_data = [slice(local.split_user_data, 0, 9), local.exchange_rate_env_string, local.split_user_data[10]]
    joined_user_data = join("\n", flatten(local.parsed_user_data))
}


output "data" {
    value = local.joined_user_data
}
```

##### **`lib.go`**

```golang
package lib
import (
	"net/http"
	"encoding/json"
	"io/ioutil"
	"fmt"
	"log"
)

// API Docs can be found at
// https://fiscaldata.treasury.gov/api-documentation/

const baseUrl = "https://api.fiscaldata.treasury.gov/services/api/fiscal_service/v1/accounting/od/rates_of_exchange" 

type Record struct {
	Currency string `json:"country_currency_desc"`
	ExchangeRate string `json:"exchange_rate"`
	CreatedAt string `json:"record_date"`
}

type Metadata struct {
	Count int `json:"count"`
	Labels map[string]string `json:"labels"`
	DataTypes map[string]string `json:"dataTypes"`
	DataFormats map[string]string `json:"dataFormats"`
	TotalCount int `json:"total-count"`
	Links map[string]string `json:"links"`
}

type Response struct {
	Data []Record `json:"data"`
	Metadata Metadata `json:"meta"`
}

type RequestOptions struct {
	Currencies string `tf:"currencies"`
}

func ExchangeRate(options RequestOptions) Record {
	var response Response
	queryParams := fmt.Sprintf("fields=country_currency_desc,exchange_rate,record_date&filter=country_currency_desc:in:(%s),record_date:gte:2020-01-01&sort=-record_date&page[size]=1", options.Currencies)
	requestUrl := fmt.Sprintf("%s?%s", baseUrl, queryParams)
	resp, err := http.Get(requestUrl)

	if err != nil {
		log.Fatal(err)
	}

	body, err := ioutil.ReadAll(resp.Body)

	if err != nil {
		log.Fatal(err)
	}

	err = json.Unmarshal(body, &response)
	
	if err != nil {
		log.Fatal(err)
	}

	return response.Data[0]
}
```

```bash
tofu init
tofu apply -auto-approve
```

## Challenges

Want to keep practicing before Week 4? Here are some challengs:

1. **Tag your ec2 instances with a random [cat fact](https://catfact.ninja/)**: Using the ExchangeRate function as a guide, retrieve a cat fact and add it as a tag to your ec2 instance module.
2. **Add the conversion rate for the Mexican Peso**: Using the [api documentation](https://fiscaldata.treasury.gov/datasets/treasury-reporting-rates-exchange/treasury-reporting-rates-of-exchange), add the conversion rate for the Peso to your environment variables.
3. **Use a ternary expression to sort a user provided list and enable user configuration of the sort order**: Use the [sort](https://developer.hashicorp.com/terraform/language/functions/sort) and [reverse](https://developer.hashicorp.com/terraform/language/functions/reverse) functions in a ternary to sort a list by ascending or descending order based on a user input variable.
