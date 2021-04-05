
variable "box_version" {
  type    = string
  default = ""
}

variable "desktop" {
  type    = string
  default = "lxde"
}

variable "cpus" {
  type    = string
  default = "2"
}

variable "disk_size" {
  type    = string
  default = "100000"
}

variable "docker_compose_version" {
  type    = string
  default = "1.26.2"
}

variable "headless" {
  type    = string
  default = "true"
}

variable "http_proxy" {
  type    = string
  default = "${env("http_proxy")}"
}

variable "https_proxy" {
  type    = string
  default = "${env("https_proxy")}"
}

variable "iso_checksum" {
  type    = string
  default = "caf3fd69c77c439f162e2ba6040e9c320c4ff0d69aad1340a514319a9264df9f"
}

variable "iso_checksum_type" {
  type    = string
  default = "sha256"
}

variable "iso_path" {
  type    = string
  default = "iso"
}

variable "iso_url" {
  type    = string
  default = "iso"
}

variable "mac_address" {
  type    = string
  default = "00:15:5D:BD:4B:0C"
}

variable "memory" {
  type    = string
  default = "4096"
}

variable "no_proxy" {
  type    = string
  default = "${env("no_proxy")}"
}

variable "nvm_version" {
  type    = string
  default = "0.37.2"
}

variable "ssh_password" {
  type    = string
  default = "vagrant"
}

variable "ssh_username" {
  type    = string
  default = "vagrant"
}

variable "ubuntu_version" {
  type    = string
  default = "ubuntu-20.04-live-server"
}

variable "usergroup" {
  type    = string
  default = "vagrant"
}

variable "userhome" {
  type    = string
  default = "/home/vagrant"
}

variable "username" {
  type    = string
  default = "vagrant"
}

variable "version" {
  type    = string
  default = ""
}

variable "vagrantfile_template" {
  type    = string
  default = "Vagrantfile.box.template"
}

source "virtualbox-iso" "sourceIso" {
  boot_command             =  [
    "<enter><enter><f6><esc><wait> ",
    "autoinstall ds=nocloud-net;seedfrom=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<enter><wait>"
  ]
  boot_wait                = "5s"
  disk_size                = "${var.disk_size}"
  guest_additions_mode     = "disable"
  guest_os_type            = "Ubuntu_64"
  hard_drive_discard       = "true"
  hard_drive_interface     = "sata"
  hard_drive_nonrotational = "true"
  headless                 = "${var.headless}"
  http_directory           = "http"
  iso_checksum             = "${var.iso_checksum}"
  iso_url                  = "${var.iso_url}"
  output_directory         = "./output-virtualbox-${var.desktop}/"
  sata_port_count          = "2"
  shutdown_command         = "echo 'vagrant'|sudo -S shutdown -P now"
  ssh_handshake_attempts   = "200"
  ssh_password             = "${var.ssh_password}"
  ssh_port                 = 22
  ssh_timeout              = "10000s"
  ssh_username             = "${var.ssh_username}"
  vboxmanage               = [
    ["modifyvm", "{{ .Name }}", "--memory", "${var.memory}"],
    ["modifyvm", "{{ .Name }}", "--cpus", "${var.cpus}"]
  ]
  virtualbox_version_file  = ".vbox_version"
  vm_name                  = "${var.ubuntu_version}-${var.box_version}-${var.desktop}"
}

build {
  sources = ["sources.virtualbox-iso.sourceIso"]

  provisioner "file" {
    destination = "/tmp/common.sh"
    source      = "scripts/common.sh"
  }

  provisioner "shell" {
    environment_vars  = [
      "BOX_VERSION=${var.box_version}",
      "DEBIAN_FRONTEND=noninteractive",
      "DESKTOP=${var.desktop}",
      "DOCKER_COMPOSE_VERSION=${var.docker_compose_version}",
      "NVM_VERSION=${var.nvm_version}",
      "SSH_PASSWORD=${var.ssh_password}",
      "SSH_USERNAME=${var.ssh_username}",
      "USERGROUP=${var.usergroup}",
      "USERHOME=${var.userhome}",
      "USERNAME=${var.username}",
      "http_proxy=${var.http_proxy}",
      "https_proxy=${var.https_proxy}",
      "no_proxy=${var.no_proxy}"
    ]
    execute_command   = "echo '${var.ssh_password}'|{{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    expect_disconnect = false
    scripts           = [
      "./scripts/00-init.sh",
      "./scripts/10-update.sh",
      "./scripts/20-network.sh",
      "./scripts/30-docker.sh",
      "./scripts/40-kubernetes.sh",
      "./scripts/60-motd.sh",
      "./scripts/70-final-config.sh",
      "./scripts-desktop/00-common-conf.sh",
      "./scripts-desktop/10-install-desktop-gnome.sh",
      "./scripts-desktop/20-install-desktop-lxde.sh",
      "./scripts-desktop/30-install-desktop-common.sh",
      "./scripts-desktop/40-install-browsers.sh",
      "./scripts-desktop/41-install-vscode.sh",
      "./scripts-desktop/42-install-jetbrains-toolbox.sh",
      "./scripts-desktop/43-install-code-checker.sh",
      "./scripts-desktop/45-install-other-softwares.sh",
      "./scripts-desktop/70-motd.sh"
    ]
  }

  provisioner "shell" {
    environment_vars  = ["DEBIAN_FRONTEND=noninteractive", "http_proxy=${var.http_proxy}", "https_proxy=${var.https_proxy}", "no_proxy=${var.no_proxy}"]
    execute_command   = "echo '${var.ssh_password}'|{{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    expect_disconnect = true
    scripts           = [
      "./scripts/100-dist-upgrade.sh"
    ]
  }

  provisioner "shell" {
    environment_vars  = ["http_proxy=${var.http_proxy}", "https_proxy=${var.https_proxy}", "no_proxy=${var.no_proxy}"]
    execute_command   = "echo '${var.ssh_password}'|{{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    expect_disconnect = false
    scripts           = [
      "./scripts/cleanup.sh"
    ]
  }

  post-processor "vagrant" {
    keep_input_artifact  = true
    compression_level    = 9
    output               = "./output-virtualbox-${var.desktop}/${var.ubuntu_version}-${var.box_version}-${var.desktop}.box"
    vagrantfile_template = "${var.vagrantfile_template}"
  }
}
