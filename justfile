
build:
    gcc -o main main.s constants.s data.s
    @echo "sucessfully built main"

run: build
    ./main