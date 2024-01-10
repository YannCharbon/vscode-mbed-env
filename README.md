# Installation
Make script executable with `sudo chmod +x deploy_dev_env.sh` and run it with `./deploy_dev_env.sh`

The script will install the following elements:
- VSCode (with following extensions)
  - Task runner (available in the left tab to easily run compilation and flashing boards)
  - Cortex-debug
  - C/C++ intellisense
- arm-none-eabi toolchain
- Mbed CLI 1
- OpenOCD debugger
- Jlink debugger

# Usage
The development environment is standalone and self-contained. This allows to avoid conflicting with other installations of VSCode, etc. It implies that, in order to have access to it, the envrionment variables related to it must be added/created.
To keep it simple, `.bashrc` must not be altered. Instead [direnv](https://direnv.net/) is used to only override the environment folder where an Mbed OS project exists.

Use the `mbedify.sh` command (should be accessible anywhere using the terminal) to enable the environment in a given folder. This will create a `.envrc` file at the root of the directory with the required environment variable.

To verify the installation, there is a test project that is available in this repo.
