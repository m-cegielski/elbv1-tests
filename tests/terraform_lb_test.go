package test

import (
	"crypto/tls"
	"fmt"
	"strings"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestTerraformAwsElb(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		VarFiles:     []string{"envs/dev2.tfvars"},
		NoColor:      true,

		Vars: map[string]interface{}{
			"id": uniqueID,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	lbEndpoint := terraform.Output(t, terraformOptions, "elb_dns_name")
	ec2PrivateIp := terraform.Output(t, terraformOptions, "ec2_private_ip")
	expectedText := "ip-" + strings.ReplaceAll(ec2PrivateIp, ".", "-")

	httpsUrl := fmt.Sprintf("https://%s", lbEndpoint)
	httpUrl := fmt.Sprintf("http://%s", lbEndpoint)
	tcpUrl := fmt.Sprintf("http://%s:8080", lbEndpoint)
	urlBody := fmt.Sprintf("<html><body><h1>%s</h1></body></html>", expectedText)

	tlsConfig := tls.Config{InsecureSkipVerify: true}
	maxRetries := 15
	timeBetweenRetries := 10 * time.Second

	http_helper.HttpGetWithRetry(t, httpsUrl, &tlsConfig, 200, urlBody, maxRetries, timeBetweenRetries)
	http_helper.HttpGetWithRetry(t, httpUrl, nil, 200, urlBody, maxRetries, timeBetweenRetries)
	http_helper.HttpGetWithRetry(t, tcpUrl, nil, 200, urlBody, maxRetries, timeBetweenRetries)
}
