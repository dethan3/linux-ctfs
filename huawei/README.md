# Linux Command Line CTF Lab - Huawei Cloud

## Prerequisites

1. [Terraform](https://developer.hashicorp.com/terraform/install) (v1.9.0 or later)
2. [Huawei Cloud CLI (hcloud)](https://support.huaweicloud.com/intl/en-us/qs-hcli/hcli_02_003.html) (optional)
3. A Huawei Cloud account with Access Key and Secret Key

## Getting Started

1. Clone this repository:

    ```sh
    git clone https://github.com/learntocloud/linux-ctfs
    cd linux-ctfs/huawei
    ```

2. Create a `terraform.tfvars` file with your credentials:

    ```hcl
    hw_access_key = "YOUR_ACCESS_KEY"
    hw_secret_key = "YOUR_SECRET_KEY"
    hw_region     = "cn-north-4"  # Optional, defaults to Beijing
    ```

    > **Note:** You can obtain Access Key and Secret Key from [Huawei Cloud Console](https://console.huaweicloud.com/) → My Credentials → Access Keys.

3. Initialize and apply Terraform:

    ```sh
    terraform init
    terraform apply
    ```

    Type `yes` when prompted.

4. Note the `public_ip_address` output—you'll use this to connect.

## Available Regions

| Region Code | Location |
|-------------|----------|
| cn-north-4 | Beijing |
| cn-east-3 | Shanghai |
| cn-south-1 | Guangzhou |
| ap-southeast-1 | Hong Kong |
| ap-southeast-3 | Singapore |

## Accessing the Lab

1. Connect via SSH:

    ```sh
    ssh ctf_user@<public_ip_address>
    ```

1. On first login you will be asked if you want to add fingerprints to the known hosts file; type `yes` and press Enter.

1. When prompted, enter the password: `CTFpassword123!`

## Cleaning Up

Destroy the resources when you're done to avoid charges:

```sh
terraform destroy
```

Type `yes` when prompted.

## Troubleshooting

1. Ensure your Access Key and Secret Key are valid
2. Check that you're using Terraform v1.9.0 or later
3. Verify you have permissions to create ECS, VPC, and Security Group resources
4. If the Ubuntu image is not found, check available images with:

    ```sh
    terraform console
    > data.huaweicloud_images_image.ubuntu
    ```

If problems persist, please open an issue in this repository.

## Security Note

This lab uses password authentication for simplicity. In production, use key-based authentication.
