# Create the IAM role for rds_shutdown
resource "aws_iam_role" "rds_shutdown" {
  name = "${var.iamrole}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"  # This is to allow Lambda to assume the role
        }
      }
    ]
  })
}

# Attach AmazonRDSFullAccess policy to the role
resource "aws_iam_role_policy_attachment" "rds_full_access" {
  role       = aws_iam_role.rds_shutdown.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  # Define policy with the condition for the CloudWatch alarm ARN
}

# Attach AWSLambdaBasicExecutionRole policy to the role
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.rds_shutdown.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach CloudWatchEventsFullAccess policy to the role
resource "aws_iam_role_policy_attachment" "cloudwatch_events_full_access" {
  role       = aws_iam_role.rds_shutdown.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchEventsFullAccess"
}

#Generates an archive from content , a file, or a directory of files.
data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/python/"
  output_path = "${path.module}/python/python.zip"
}

#Create a lamda function
resource "aws_lambda_function" "lambda_rds" {
  function_name = "${var.lambdaname}"
  role          = aws_iam_role.rds_shutdown.arn
  handler       = "python.lambda_handler"  # Modify based on your Lambda function entry point
  runtime       = "python3.13"     # Example runtime (can be Python, Node.js, etc.)
  filename      = "${path.module}/python/python.zip"    # Path to your zipped Lambda function package
}

# Lambda permission for CloudWatch to invoke the Lambda function
resource "aws_lambda_permission" "allow_cloudwatch_invoke" {
  statement_id  = "AllowCloudWatchAlarmsInvoke"
  action        = "lambda:InvokeFunction"
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  function_name = aws_lambda_function.lambda_rds.function_name
  source_arn    = aws_cloudwatch_metric_alarm.rds_cpu_utilization_high.arn
}

# Create a CloudWatch Alarm for RDS CPU Utilization
resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization_high" {
  alarm_name                = "${var.alarmname}"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 4  # Number of periods (10-minute windows)
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/RDS"
  period                    = 600  # 10 minutes
  statistic                 = "Average"
  threshold                 = 1.5  # CPU Utilization threshold in percentage
  actions_enabled           = true
  alarm_description         = "This alarm triggers when RDS CPU utilization exceeds 1.5% for 3 out of 4 consecutive 10-minute periods."
  alarm_actions             = [aws_lambda_function.lambda_rds.arn]  # Lambda ARN to trigger when alarm goes off
  insufficient_data_actions = []

  # Optional: Set RDS cluster identifier (replace with your RDS cluster ID)
  dimensions = {
    DBClusterIdentifier = "${var.DBClusterName}"  # Replace with your RDS cluster ID
  }
  # Set the threshold for the number of periods the alarm must breach the threshold
  # to trigger the alarm (3 out of 4 periods)
  datapoints_to_alarm = 3
}