<<<<<<< HEAD
# point to the dotnet installation location
export DOTNET_ROOT=$HOME/.dotnet
export PATH="$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools:$DOTNET_ROOT/sdk"

=======
>>>>>>> ec93398 (docker function)
# import user-defined binaries
export PATH="${PATH}:${HOME}/.local/bin"

# environment variables
export EDITOR=nvim

export GEM_HOME="${HOME}/.local/share/gem/ruby/3.4.0"
export GEM_PATH="${GEM_HOME}:$(gem env gempath)"
export PATH="${PATH}:${GEM_HOME}/bin"

# cargo installs
export PATH="${PATH}:${HOME}/.cargo/bin"

<<<<<<< HEAD
=======
export DOCKER_PHP_IMAGE="php-xdebug-8.5:latest"
>>>>>>> ec93398 (docker function)
