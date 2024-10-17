resource "aws_iam_role_policy_attachment" "iam_policy" {
  role = aws_iam_role.iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
