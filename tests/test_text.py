from factory_lib import slugify


def test_slugify_basic():
    assert slugify("Hello, World!") == "hello-world"
