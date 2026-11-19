import pytest

import factory_lib
from factory_lib import slugify, truncate


def test_slugify_basic():
    assert slugify("Hello, World!") == "hello-world"


def test_truncate_shorter_than_max():
    assert truncate("Hello", 10) == "Hello"


def test_truncate_equal_to_max():
    assert truncate("Hello", 5) == "Hello"


def test_truncate_longer_than_max():
    result = truncate("Hello, World!", 8)
    assert result == "Hello, …"
    assert len(result) == 8


def test_truncate_ends_with_unicode_ellipsis():
    result = truncate("abcdef", 4)
    assert result == "abc…"
    assert not result.endswith("...")


def test_truncate_max_len_one():
    assert truncate("Hello", 1) == "…"


def test_truncate_empty_string():
    assert truncate("", 1) == ""


@pytest.mark.parametrize(
    ("text", "max_len"),
    [("Hello", 0), ("Hello", -3), ("", 0)],
)
def test_truncate_invalid_max_len(text, max_len):
    with pytest.raises(ValueError, match="max_len"):
        truncate(text, max_len)


@pytest.mark.parametrize("n", range(1, 21))
def test_truncate_length_invariant(n):
    text = "abcdefghij"
    assert len(truncate(text, n)) == min(len(text), n)


def test_truncate_does_not_modify_input():
    text = "Hello, World!"
    truncate(text, 3)
    assert text == "Hello, World!"


def test_truncate_exported():
    assert "truncate" in factory_lib.__all__
    assert factory_lib.truncate is truncate
