function scratch -d "Create an ephemeral temp workspace (via wincent)"
    set -l dir (mktemp -d)
    set -l orig $PWD
    cd $dir
    echo "Scratch workspace: $dir"
    echo "Type 'exit' to leave and clean up."

    # Spawn a sub-shell so "exit" returns here for cleanup.
    fish

    cd $orig
    rm -rf $dir
    echo "Cleaned up $dir"
end
