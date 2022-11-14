resource "aws_instance" "web" {
  vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]
  ami                  = "ami-0ca285d4c2cda3300"
  instance_type        = "t3.micro"
  key_name             = "yourKeyHere"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  tags = {
    Name = "devop-test"
  }
}

resource "aws_s3_bucket" "bucket_creation" {
  bucket        = "eg-s3bucket"
  force_destroy = true
}

resource "aws_iam_policy" "policy" {
  name        = "policy-to-assign"
  description = "policy to attach"
  policy      = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.bucket_creation.bucket}", "arn:aws:s3:::${aws_s3_bucket.bucket_creation.bucket}/*"]
    }]
}
  EOT
}

resource "aws_iam_role" "S3ReadWrite" {
  name = "S3ReadWrite"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ec2_policy_role" {
  name       = "ec2-attachment"
  roles      = [aws_iam_role.S3ReadWrite.name]
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.S3ReadWrite.name
}