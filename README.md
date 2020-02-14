# Sample Terraform Modules and Tests

This repository contains the sample modules and tests referenced in my article.

## Running the samples

You'll need the following to run these examples:

1. A VPC with private and public subnets
2. A Route53 zone
3. The AWS CLI configured with valid credentials
4. Terraform 12

Navigate into the directory of the example you wish to run and run

```
terraform plan
```

or

```
terraform plan --var-file path/to/varfile
```

## Running the tests

In addition to the above requirements, you will also need the following

1. Go
2. This repository must be place in $GOPATH/src

Before you begin, make sure to update the tfvars file in the tests folder to contain values relevant to your AWS account. You will also need to update `expectedUrl` in the test file for the `app-infrastructure-good-example` example.

Navigate into the tests repo of the module you wish to run the tests for, then run

```
dep init
dep ensure
go test -v
```