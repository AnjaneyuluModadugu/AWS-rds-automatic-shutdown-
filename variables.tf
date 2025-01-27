variable "iamrole" {
    type = string
    description = "Iam role creation"
}

variable "lambdaname" {
    type = string
    description = "Used for creating the lambda function"
}

variable "alarmname" {
    type = string
    description = "Used for creating the alaram"
}

variable "DBClusterName" {
  type = string
  description = "used to Db cluster naming"
}