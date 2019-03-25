# Ramdisk-to-Go

## Usage

```bash
./rd2go.sh <action> <name> [<size>]
  <action>: create|destroy|help
  <name>: mountpoint name
  <size>: ramdisk size in megabytes
```

### Examples

#### Create Ramdisk:
```bash
./rd2go.sh create test 1024
```

#### Destroy Ramdisk:
```bash
./rd2go.sh destroy test
```
