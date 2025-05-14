```hcl
###############################################################################
# Detect the OS
###############################################################################

# Full path to the helper that exists only on Windows
locals {
  windows_helper = "${abspath(path.module)}\\printf.cmd"
}

# If the helper file exists, we’re on Windows; otherwise assume Linux
data "external" "detect_os" {
  program = fileexists(local.windows_helper) ? [local.windows_helper, "{\"os\":\"Windows\"}"] : ["printf", "{\"os\":\"Linux\"}"]
}

locals {
  os         = data.external.detect_os.result.os
  is_windows = lower(local.os) == "windows"
  is_linux   = lower(local.os) == "linux"
}

data "http" "public_ip" {
  url = "https://checkip.amazonaws.com"
  # 2‑second timeout is plenty for this endpoint
  request_timeout_ms = 2000
}

######################  Linux  ######################
data "external" "private_ip_linux" {
  count       = local.is_linux ? 1 : 0
  working_dir = var.working_dir == null ? path.module : var.working_dir
  program = [
    "bash", "-c",
    "IP=$(hostname -I | awk '{print $1}'); printf '{\"private_ip\":\"%s\"}' \"$IP\""
  ]
}

######################  Windows  ######################
data "external" "private_ip_windows" {
  count       = local.is_windows ? 1 : 0
  working_dir = var.working_dir == null ? path.module : var.working_dir

  program = [
    "powershell",
    "-Command",
    "$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike '*Loopback*' -and $_.IPAddress -notlike '169.*'} | Select-Object -First 1 -ExpandProperty IPAddress); Write-Output ('{\"private_ip\":\"'+$ip+'\"}')"
  ]
}


locals {
  private_ip = local.is_linux ? data.external.private_ip_linux[0].result.private_ip : data.external.private_ip_windows[0].result.private_ip
  public_ip  = chomp(data.http.public_ip.response_body)
}
```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | n/a |
| <a name="provider_http"></a> [http](#provider\_http) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [external_external.detect_os](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.private_ip_linux](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.private_ip_windows](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [http_http.public_ip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_working_dir"></a> [working\_dir](#input\_working\_dir) | The working directory for the module | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_is_linux"></a> [is\_linux](#output\_is\_linux) | True if the OS is Linux |
| <a name="output_is_windows"></a> [is\_windows](#output\_is\_windows) | True if the OS is Windows |
| <a name="output_os"></a> [os](#output\_os) | The OS that is running the commands |
| <a name="output_private_ip_address"></a> [private\_ip\_address](#output\_private\_ip\_address) | The private IP address of caller |
| <a name="output_public_ip_address"></a> [public\_ip\_address](#output\_public\_ip\_address) | The public IP address of caller |
