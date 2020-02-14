package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestSimpleTest(t *testing.T) {
	// runs in parallel if we have multiple tests
	t.Parallel()

	// Setup Terraform Config
	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		VarFiles:     []string{"tests/simple_test_input.tfvars"},
	}

	// Queue up the eventual destroy, and then create IAC
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}
