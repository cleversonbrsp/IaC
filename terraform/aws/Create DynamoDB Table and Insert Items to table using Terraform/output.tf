output "table_arn1" {
    value = aws_dynamodb_table.dynamodb_table.arn
    description = "DynamoDB Table created successfully"
}