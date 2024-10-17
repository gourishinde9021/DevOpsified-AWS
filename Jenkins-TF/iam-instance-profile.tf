resource "aws_iam_instance_profile" "instace_profile" {
  name = "Jenkins-instance-profile"
  role = aws_iam_role.iam-role.name
}