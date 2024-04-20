data "aws_iam_policy_document" "assume-role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "vault-kms-unseal" {
  statement {
    sid       = "VaultKMSUnseal"
    effect    = "Allow"
    resources = [aws_kms_key.vault.arn]

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
  }
}


resource "aws_iam_role" "vault-kms-unseal" {
  name               = "vault-kms-role"
  assume_role_policy = data.aws_iam_policy_document.assume-role.json
}

resource "aws_iam_role_policy" "vault-kms-unseal" {
  name   = "vault-KMS-Unseal"
  role   = aws_iam_role.vault-kms-unseal.id
  policy = data.aws_iam_policy_document.vault-kms-unseal.json
}

resource "aws_iam_instance_profile" "vault-kms-unseal" {
  name = "vault-kms-unseal"
  role = aws_iam_role.vault-kms-unseal.name
}