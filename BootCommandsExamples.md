Ubuntu 20.10 server
```json
"boot_command": [
  "e<wait>",
  "<del><del><del><del><del><del><del><del><del><del>",
  "<del><del><del><del><del><del><del><del><del><del>",
  "<del><del><del><del><del><del><del><del><del><del>",
  "<del><del><del><del><del><del><del><del><del><del>",
  "<del><del><del><del><del><del><del><del><del><del>",
  "<del><del><del><del><del><del><del><del><del><del>",
  "<del><del><del><del><del><del><del><del><del><del>",
  "<del><del><del><del><del><del><del><del><del><del>",
  "<del><del><del><del><del><del><del><del><del><del>",
  "<del><del><del><del><del><del><del><del><del><del>",
  "<del><del><del><del><del><del><del><del><del><del>",
  "set gfxpayload=keep<enter>",
  "linux /casper/vmlinuz 'ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/' quiet autoinstall ---<enter>",
  "initrd /casper/initrd<enter>",
  "<wait><f10>"
]
```