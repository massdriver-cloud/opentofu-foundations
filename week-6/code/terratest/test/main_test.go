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

	snsArn := terraform.Output(t, terraformOptions, "sns_topic_arn")
	sqsUrl := terraform.Output(t, terraformOptions, "sqs_queue_url")

	cfg, err := config.LoadDefaultConfig(context.Background(), config.WithRegion("us-west-2"))

	if err != nil {
		assert.Fail(t, err.Error())
	}

	snsClient := sns.NewFromConfig(cfg)
	_, err = snsClient.Publish(context.Background(), &sns.PublishInput{
		Message:  aws.String("Hello World"),
		TopicArn: aws.String(snsArn),
	})

	if err != nil {
		assert.Fail(t, err.Error())
	}

	sqsClient := sqs.NewFromConfig(cfg)

	message, err := sqsClient.ReceiveMessage(context.Background(), &sqs.ReceiveMessageInput{
		QueueUrl: aws.String(sqsUrl),
	})

	if err != nil {
		assert.Fail(t, err.Error())
	}

	assert.Greater(t, len(message.Messages), 0)
	want := "Hello World"
	got := make(map[string]string)
	err = json.Unmarshal([]byte(*message.Messages[0].Body), &got)

	if err != nil {
		assert.Fail(t, err.Error())
	}

	assert.Equal(t, got["Message"], want)
}
