genpass() {
    echo 'pseudo rnd base64 ' $1 'chars:'
    head -c $1 </dev/urandom | base64
}
