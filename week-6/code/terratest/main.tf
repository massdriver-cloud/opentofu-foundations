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