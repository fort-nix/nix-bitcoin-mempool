@test("mempool")
def _():
    assert_running("mempool")
    assert_running("nginx")
    machine.wait_until_succeeds(
        log_has_string("mempool", "Mempool Server is running on port 8999")
    )
    assert_matches(f"curl -fsS -L {ip('nginx')}:60845", "mempool - Bitcoin Explorer")

    if "regtest" in enabled_tests:
        assert_full_match(
            f"curl -fsS http://{ip('nginx')}:60845/api/v1/blocks/tip/height", str(test_data["num_blocks"])
        )
