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