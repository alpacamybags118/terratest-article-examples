package test

import (
	"testing"

	"crypto/tls"
	"fmt"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestHttpTest(t *testing.T) {
	// runs in parallel if we have multiple tests
	t.Parallel()
	expectedUrl := "sampleapp.yoursampledomain.com"

	// Setup Terraform Config
	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		VarFiles:     []string{"tests/http_test_input.tfvars"},
	}

	// Queue up the eventual destroy, and then create IAC
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Check the output to ensure its what we expect & isn't empty
	url := terraform.Output(t, terraformOptions, "siteurl")
	albID := terraform.Output(t, terraformOptions, "lb_id")

	assert.Equal(t, expectedUrl, url)
	assert.NotNil(t, albID)

	// Perform an HTTP request on the resource and ensure we get a 200.
	tlsConfig := tls.Config{}
	statusCode, body := http_helper.HttpGet(t, fmt.Sprintf("http://%s", url), &tlsConfig)

	assert.Equal(t, 200, statusCode)
	assert.NotNil(t, body)
}
