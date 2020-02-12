# rust wasm

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Current installation options:
#
#
#    default host triple: x86_64-apple-darwin
#      default toolchain: nightly
#                profile: complete
#   modify PATH variable: yes

# wasm-pack
curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh
cargo install cargo-generate
npm install npm@latest -g
